#this function transform json to a variable="value"; structure that can be loaded in bash using eval
#requires jq installed
format_json2(){
  jq -r --arg prefix "${1}" --arg bk "${2}" '
    def x: . | to_entries[] |
      (if (.value | type) == "array" then
         (.key | tostring | gsub("[-|$|:|.|/]"; "_")) + "_" + (.value | x)
       elif (.value | type) == "object" then
         (.key | tostring | gsub("[-|$|:|.|/]"; "_")) + "_" + (.value | x)
       else
         (.key | tostring | gsub("[-|$|:|.|/| ]"; "_")) + "=" + (.value | tojson) + ($bk | tostring)
       end);
    x | ($prefix + "_") + .
  '
}

#this function aggregate lines returned by format_json to use in loops
#example
#cat file.json|format_json "var" "\n;"|agg
agg() {
awk 'BEGIN {
		str1="_1_"
    }
	{
		str0=$0
		n2=match(str0,/=/)
		n1=match(str0,/_[0-9]+_|_aad_[0-9a-zA-Z]+_|_vssgp_[0-9a-zA-Z]+_/)
		if (n1>0 && n1<n2) {
			st=RSTART
			ln=RLENGTH
			str2=substr(str0,st,ln)
			sub(/_[0-9]+_|_aad_[0-9a-zA-Z]+_|_vssgp_[0-9a-zA-Z]+_/,"_",str0)
			if (str1!=str2) {
				printf("\n%s",str0)
			} else {
				printf("%s",str0)
			}
			str1=str2
		} else {
			printf("%s\n",str0)
		}
	}
	END {
		printf("\n")
	}'|grep -vE '^[[:space:]]*$'
}

#this function converts input txt to tsv
txt2tsv() {
	gawk '
	BEGIN {
		FS=";\t"; OFS="\t";
	}
	{
			# Primeira passagem: coleta nomes de variáveis
			for (i = 1; i <= NF; i++) {
				if ($i ~ /=/) {
					split($i, kv, "=");
					key = kv[1];
					gsub(/^var_/, "", key);  # remove prefixo var_
					if (key != "") {
						vars[key] = 1;
						lines[NR, i] = $i;
					}
				}
			}
			line_count = NR;
	}
	END {
			# Ordena os nomes das variáveis
			n = asorti(vars, sorted_vars);
	
			# Imprime cabeçalho
			for (i = 1; i <= n; i++) {
				printf "%s%s", sorted_vars[i], (i < n ? OFS : ORS);
			}
	
			# Segunda passagem: imprime os valores nas colunas corretas
			for (l = 1; l <= line_count; l++) {
				delete row;
				for (i = 1; (l, i) in lines; i++) {
					split(lines[l, i], kv, "=");
					key = kv[1];
					val = substr(lines[l, i], index(lines[l, i], "=") + 1);
					gsub(/^var_/, "", key);
					gsub(/^"/, "", val); gsub(/"$/, "", val);  # remove aspas externas
					#gsub(/\\"/, "\"", val);  # desescapa aspas
					#gsub(/\\n/, "\n", val);  # desescapa \n
					#gsub(/\\\$/, "\\$", val);  # mantém \$ como literal
					#gsub(/\\&/, "\\&", val);  # mantém \& como literal
					row[key] = val;
				}
				for (i = 1; i <= n; i++) {
					printf "%s%s", (sorted_vars[i] in row ? row[sorted_vars[i]] : ""), (i < n ? OFS : ORS);
				}
			}
	}'
}

github_api() {
	api_name="$1"
	api_url="$2"
 	format="$3"
	tmpfile=$(mktemp headers_${api_name}.cookie.XXXXXX)
	if [[ -z $api_url ]]; then
 		exit 1
	elif [[ "$api_url" == *\?* ]]; then
	  api_url="${api_url}&per_page=100"
	else
	  api_url="${api_url}?per_page=100"
	fi
	while : ; do
		result=$(curl -k -s -L \
			-H "Accept: application/vnd.github+json" \
			-H "Authorization: Bearer $GITHUB_TOKEN" \
			-H "X-GitHub-Api-Version: 2022-11-28" \
			-D $tmpfile \
			"${api_url}")
		#obs: o header retorna mais de um status quando trafega por proxy, por isso o filtro 'HTTP/2'
		status=$((grep 'HTTP/2' $tmpfile|| grep 'HTTP/1.1' $tmpfile)|cut -d" " -f2)
		if [[ ! "${status}" =~ ^20[0-9]*$  ]]; then
			echo "$result" | jq -r --arg api_name "$api_name" '"var_\($api_name)_error=\"\(.status) \(.message)\";\t"'
			break;
		fi
		#
		if [[ -z "$format" || "$format" == "agg" ]]; then 
			echo "${result}"|format_json2 "var_${api_name}" ";$(echo -e "\t")"|grep -v "total_count="|agg
		elif [[ "$format" == "json" ]]; then
  			echo "${result}"
		elif [[ "$format" == "list" ]]; then
     			echo "${result}"|format_json2 "var_${api_name}" ";$(echo -e "\t")"
		fi
		#
		api_url=$(grep -i "^link" $tmpfile|sed -e 's/Link://Ig' -e 's/[ <>]//g'|tr ',' '\n'|grep -i "next"|cut -d ';' -f1)
		if [[ -z "${api_url}" ]]; then
			break
	 	elif [[ "$api_url" == *\?* ]]; then
		  api_url="${api_url}&per_page=100"
		else
		  api_url="${api_url}?per_page=100"
	 	fi
	done
	rm -f $tmpfile
}

#function to install tools on $HOME/bin of agent runner 
install_tools() {
	echo "Install tools"
	install_dir=$1
 	if [[ -z $install_dir ]]; then install_dir=$HOME/bin; fi
	if [[ ! -d $install_dir ]]; then mkdir $install_dir; fi
	if ! [[ "$PATH" =~ "$install_dir:" ]]; then
	     	export PATH="$install_dir:$PATH"
      		if [[ ! -z $GITHUB_PATH ]]; then echo "$install_dir" >> $GITHUB_PATH; fi
	fi
 	echo "PATH=$PATH"
	#instalar yq se nao existir
	echo "------------------------"
	if ! which yq; then
	  curl -fsSL -o $install_dir/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 && \
	  chmod +x $install_dir/yq
  fi
	yq --version
	#instalar jq se nao existir
	echo "------------------------"
	if ! which jq; then
	  curl -fsSL -o $install_dir/jq https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-linux-amd64 && \
	  chmod +x $install_dir/jq
	fi
 	jq --version
	#instala terraform se nao existir
	echo "------------------------"
	if ! which terraform; then
	  curl -fsSL https://releases.hashicorp.com/terraform/1.12.1/terraform_1.12.1_linux_amd64.zip -o $install_dir/terraform.zip && \
	  unzip -o -q $install_dir/terraform.zip -d $install_dir && \
	  rm -f $install_dir/terraform.zip && \
	  chmod +x $install_dir/terraform
	fi
 	terraform --version
 	echo "------------------------"
}
