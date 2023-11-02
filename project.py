#!/usr/bin/python

#student: s7 David lim
#class: CFC020823
#trainer: James

#import the needed modules below
import os
import platform		#needed for checking the os
import subprocess 	#needed for checking ip addresses
import psutil		#needed for checking the disk
import time			#needed for the timer

def check_os():
	os = platform.system() #platform.system() will be able to retriesve the os
	version = platform.release() #platform.release() will be able to retrieve the os version
	print(f'The OS version of your machine is {os}, and the version is {version}') #print the whole thing with os and version
             
def check_ip():
    #private_ip
    result = subprocess.run(["ip", "route"], stdout=subprocess.PIPE, text=True) #run shell commands from within a Python
    private = result.stdout #save the result of ip route as if in terminal
    lines = private.split('\n') #apply split
    for line in lines: #loop
        if 'src' in line:
            private_ip = line.split('src')[1].split()[0] #store the result(ip address)
    print(' ')
    print(f'Your private IP Address is {private_ip} ') #print stored ip address

    #public_ip
    result = subprocess.run(["curl", "-s", "ifconfig.me"], stdout=subprocess.PIPE, text=True) #use shell to curl ifconfig.me
    public_ip = result.stdout.strip() #store the result(ip address)
    print(f'Your public IP Address is {public_ip} ') #print stored ip address

    #default_gateway
    result = subprocess.run(["ip", "route", "show", "0.0.0.0/0"], stdout=subprocess.PIPE, text=True) #use shell to 'ip route show 0.0.0.0/0'
    output = result.stdout
    parts = output.split()
    default_gateway = parts[2]
    print(f'Your default gateway is {default_gateway} ') #print gateway
		
def check_disk(path='/'): #root
    disk = psutil.disk_usage(path)# tell psutil.disk_ usage to root
    #print(disk.total)	#test if disk.total is working
    #print(disk.free)	#test if disk.free is working
    #print(disk.used)	#test if disk.used is working
    total_size_gb = disk.total / (2**30)  # Convert bytes to gigabytes
    free_space_gb = disk.free / (2**30)
    used_space_gb = disk.used / (2**30)
    #print(total_size_gb) # checking if the total size works, 
    #print(free_space_gb) # result too long
    #print(used_space_gb)
    print(' ')
    print(f"Total Disk Size: {total_size_gb:.2f} GB") # two decimal places.
    print(f"Free Disk Space: {free_space_gb:.2f} GB")
    print(f"Used Disk Space: {used_space_gb:.2f} GB")
	
def check_topdir():
	# Determine the root directory based on the platform
	if platform.system() == 'Windows':
		root_directory = 'C:\\'  # Windows root directory
	else:
		root_directory = '/'  # Unix-like root directory

	directory_info = [] # Create a list to store directory names and sizes

	for directory_entry in os.scandir(root_directory): # Iterate through directory entries in the root directory
		try:
			if directory_entry.is_dir(): #if is dir then check size
				dir_size = sum(f.stat().st_size for f in os.scandir(directory_entry.path) if f.is_file()) # Calculate the size by summing the sizes of files in the directory
				directory_info.append((directory_entry.path, dir_size)) #add result to directory_info list
		except PermissionError as e:        
			pass # Ignore permission errors and continue iterating

	directory_info.sort(key=lambda x: x[1], reverse=True) # Sort the list by directory size (in descending order)  
	print(' ')
	print('Top 5 Largest Directories:') # Print the top five directories with their names and sizes
	for directory, size in directory_info[:5]:
		print(f'{directory}: {size} bytes')
	
def check_cpu():
	try: # Code that might raise a KeyboardInterrupt
		while True:#so it will keep looping after 10sec
			cpu_percent = psutil.cpu_percent(interval=1)  # Get the CPU usage for the last 1 second
			print(' ')
			print(f"CPU Usage: {cpu_percent}%") #print CPU usage: then the %
			time.sleep(10)  # Refresh every 10 seconds
        
	except KeyboardInterrupt: # catch the error
		print(' ')
		print("Script was manually terminated.")
        
#below are the fuction
check_os()
check_ip()
check_disk()
check_topdir()
check_cpu()

