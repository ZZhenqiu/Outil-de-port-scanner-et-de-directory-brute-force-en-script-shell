#!/bin/bash

if [ $# -eq 0 ]; then
    echo
    echo "Bonjour, ce programme propose deux actions : 1) Port scanner 2) Directory brute force"
    echo
    echo "Pour utiliser le 1), veuillez utiliser la commande suivante :"
    echo -e "\e[33m./script.sh <target_ip>\e[0m"
    echo
    echo "Pour utiliser le 2), veuillez utiliser la commande suivante :"
    echo -e "\e[33m./script.sh <target_url> <wordlist> (extension optionnelle)\e[0m"
    echo
    exit 1
fi

# Si l'utilisateur choisit l'action 1 (Port scanner)
if [ $# -eq 1 ]; then
    target_ip=$1
    open_ports=false

    echo "Scanning ports on $target_ip..."
    for port in {1..1024}; do
        (echo >/dev/tcp/$target_ip/$port) >/dev/null 2>&1 && { echo "Port $port is open"; open_ports=true; }
    done

    if [ "$open_ports" = false ]; then
        echo "No open ports found on $target_ip."
    fi
fi

# Si l'utilisateur choisit l'action 2 (Directory brute force)
if [ $# -ge 2 ]; then
    target_url=$1
    wordlist_file=$2
    extensions=$3

    # Vérifie si curl est installé
    if ! command -v curl &> /dev/null; then
        echo -e "\e[33mError: curl is not installed. Please install curl.\e[0m"
        exit 1
    fi

    # Vérifie si le fichier de liste de mots existe
    if [ ! -f "$wordlist_file" ]; then
        echo -e "\e[33mError: Wordlist file not found.\e[0m"
        exit 1
    fi

    # Transforme la chaîne d'extensions en un tableau
    IFS=' ' read -r -a extensions_array <<< "$extensions"

    # Variable pour indiquer si des répertoires ont été trouvés
    found_directories=false

    # Lecture de la liste de mots
    while IFS= read -r directory; do
        # Si des extensions sont spécifiées, teste chaque répertoire avec ces extensions
        if [ -n "$extensions" ]; then
            for extension in "${extensions_array[@]}"; do
                full_url="$target_url/$directory.$extension"
                response_code=$(curl -s -o /dev/null -w "%{http_code}" "$full_url")

                if [ "$response_code" -ne 404 ] && [ "$response_code" -ne 000 ]; then
                    echo "Found: $full_url (HTTP $response_code)"
                    found_directories=true
                fi
            done
        else
            # Sinon, teste le répertoire lui-même
            full_url="$target_url/$directory"
            response_code=$(curl -s -o /dev/null -w "%{http_code}" "$full_url")

            if [ "$response_code" -ne 404 ] && [ "$response_code" -ne 000 ]; then
                echo "Found: $full_url (HTTP $response_code)"
                found_directories=true
            fi
        fi
    done < "$wordlist_file"

    # Affiche un message si aucun répertoire n'a été trouvé
    if [ "$found_directories" = false ]; then
        echo -e "\e[33mNo directories found.\e[0m"
    fi
fi
