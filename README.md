# Graded-terraform-and-Ansible-project

# 1. Objective and summary

   The goal of this assignment is to deploy the TravelMemory MERN application on AWS with 
infrastructure created by Terraform and servers configured by Ansible, with the database kept in 
a private subnet.
What was delivered:
• Terraform code that builds a VPC with one public and one private subnet, an Internet 
Gateway, a NAT Gateway, route tables, security groups, an IAM role and two EC2 
instances, and outputs the web server's public IP.
• Terraform also generates the Ansible inventory from its own outputs, so the two tools 
stay in sync with no copy-pasting of IP addresses.
• Ansible roles that harden both servers, install and secure MongoDB 8.0 with 
authentication, and deploy the Express API and the React production build behind Nginx.
• End-to-end proof: the app loads in the browser at the web server's public IP, a trip added 
through the React form is stored in MongoDB, and the database cannot be reached from 
the internet.

# 2. Architecture

<img width="637" height="377" alt="image" src="https://github.com/user-attachments/assets/a3cb0af4-a7d5-45ac-acf3-0213e597671b" />

# 3. How the application components interact
1. Browser to Nginx: The user opens http://<web_public_ip>/. Nginx on port 80 serves the 
React production build from /var/www/travelmemory.
2. React to API: The React code calls ${REACT_APP_BACKEND_URL}/trip. This value is 
compiled into the JavaScript bundle at build time, so Ansible writes frontend/.env with the 
public IP before running npm run build. If it were left as localhost:3001, the browser 
would try to reach the user's own machine.
3. Nginx to Express: Nginx proxies /trip and /hello to Express on 127.0.0.1:3001. Port 
3001 is not opened in any security group, so the API is only reachable through Nginx.
4. Express to MongoDB: Express reads MONGO_URI from backend/.env (written by 
Ansible, mode 0600) and connects to MongoDB on the DB server's private IP, port 
27017, as a user that only has readWrite on the travelmemory database.
5. Network controls: db-sg allows 27017 only from web-sg. On top of that, UFW on the DB 
server allows 27017 only from the web server's private IP.
6. Outbound for the private subnet: The DB server has no public IP. Its route table sends 
0.0.0.0/0 to the NAT Gateway, which is how apt and the MongoDB repository are 
reached during installation.
7. Administration: SSH to the web server is allowed only from the learner's IP. SSH to the 
DB server goes through the web server as a bastion (ProxyCommand in the generated 
Ansible inventory).

# 4. Prerequisites

You need:

-   An AWS account with permissions to create VPC, EC2, IAM, EIP, NAT
    Gateway, and security groups.
-   AWS CLI v2.
-   Terraform 1.6 or later.
-   Ansible.
-   Git.
-   WSL Ubuntu or a Linux workstation.
-   A GitHub account.

Verify:

aws --version
terraform version
ansible --version

# 5. Expected structure:

``` text
travelmemory-project/
├── terraform/
│   ├── versions.tf
│   ├── variables.tf
│   ├── network.tf
│   ├── security.tf
│   ├── compute.tf
│   ├── outputs.tf
│   └── terraform.tfvars
├── ansible/
│   ├── ansible.cfg
│   ├── inventory/hosts.ini
│   ├── group_vars/all.yml
│   ├── site.yml
│   └── roles/
│       ├── common/tasks/main.yml
│       ├── mongodb/tasks/main.yml
│       ├── mongodb/templates/mongod.conf.j2
│       ├── mongodb/handlers/main.yml
│       ├── webserver/tasks/main.yml
│       ├── webserver/tasks/backend.yml
│       ├── webserver/tasks/frontend.yml
│       ├── webserver/templates/backend.env.j2
│       ├── webserver/templates/backend.service.j2
│       ├── webserver/templates/nginx.conf.j2
│       ├── webserver/templates/frontend.env.j2
│       └── hardening/tasks/main.yml
├── README.md
└── .gitignore
```
# 6. Part 1 - Infrastructure with Terraform

# AWS CLI setup and Terraform initialisation
The AWS CLI was configured with an IAM user's access key for region us-east-1, and sts get
caller-identity confirms the account. Terraform state is stored remotely in S3 with native locking 
(use_lockfile), so the state file is never committed to Git

<img width="701" height="173" alt="image" src="https://github.com/user-attachments/assets/3ccc58ae-7708-4f39-9868-65904dd6f2b8" />

<img width="894" height="143" alt="image" src="https://github.com/user-attachments/assets/ff60f843-aef1-4c75-8724-e07d1d78d9fb" />

<img width="1053" height="207" alt="image" src="https://github.com/user-attachments/assets/5ccdfd7a-6da9-4667-8fda-2080c32046e8" />

<img width="940" height="363" alt="image" src="https://github.com/user-attachments/assets/c83b60be-a497-4270-994f-4acaecedcadc" />

<img width="940" height="96" alt="image" src="https://github.com/user-attachments/assets/dc65aea2-e524-4734-8329-e7ba955e1ff5" />

<img width="940" height="339" alt="image" src="https://github.com/user-attachments/assets/400076d6-1ccb-4a9a-8810-85e9777a6ce1" />

<img width="940" height="322" alt="image" src="https://github.com/user-attachments/assets/4be975b8-fdf3-49b9-8d05-74797c493bf1" />

Verifying what was created

<img width="940" height="157" alt="image" src="https://github.com/user-attachments/assets/1b49582d-e3e6-43a9-82db-4aae576de241" />

<img width="940" height="170" alt="image" src="https://github.com/user-attachments/assets/0dc8686d-d15c-4add-afd9-b2f092915b31" />

<img width="940" height="611" alt="image" src="https://github.com/user-attachments/assets/4dc96d5d-954d-4ebd-b8ac-6b20d0eb948a" />

<img width="940" height="149" alt="image" src="https://github.com/user-attachments/assets/1d039224-4ed6-4e55-a3c6-9f34e375294e" />

# 7. Part 2 - Configuration and deployment with Ansible
Ansible configuration

<img width="940" height="214" alt="image" src="https://github.com/user-attachments/assets/69c25c8c-1a22-48f1-9874-f4a32596d37b" />

<img width="940" height="422" alt="image" src="https://github.com/user-attachments/assets/ac90a104-89bf-4ac0-a795-8db3c2515adb" />

Roles

<img width="607" height="223" alt="image" src="https://github.com/user-attachments/assets/40a35744-86d5-4638-9036-5dfa07d135b9" />

**Securing MongoDB:** Authorization is enabled in mongod.conf from the first start. The first admin 
user is created through MongoDB's localhost exception, and the application user is then created 
with readWrite on travelmemory only. Passwords are passed to mongosh through environment 
variables and the tasks use no_log, so they never appear in the output.
**Running the API: ** Express runs as a dedicated system user under systemd (Restart=always, 
NoNewPrivileges, ProtectSystem), so it starts on boot and restarts on failure.

Playbook run

ansible-playbook site.yml ran four plays: baseline and hardening on both hosts, MongoDB on the 
DB server, the web tier on the web server, and a final verification play that calls /hello and /trip 
through Nginx

<img width="940" height="483" alt="image" src="https://github.com/user-attachments/assets/9686904f-949a-403a-8371-ee6a80fe2e25" />

<img width="940" height="466" alt="image" src="https://github.com/user-attachments/assets/18768996-db6c-4212-a11c-da7c2ee22143" />

<img width="940" height="330" alt="image" src="https://github.com/user-attachments/assets/374da856-71f4-45a5-9dd1-2d33bd4cb73e" />

<img width="940" height="433" alt="image" src="https://github.com/user-attachments/assets/c6a47e94-73ba-466d-853f-cc8f8e72a456" />

<img width="940" height="488" alt="image" src="https://github.com/user-attachments/assets/3c0fccb0-6faa-4925-bdf4-b9c9bc6c765c" />

<img width="940" height="477" alt="image" src="https://github.com/user-attachments/assets/4fc5e301-76e9-4a2f-b74f-3eacf9f0eb6a" />

<img width="940" height="482" alt="image" src="https://github.com/user-attachments/assets/7024d540-4408-46d2-9787-64bbeb308369" />

Verifying the server
On the DB server, mongod is enabled and listens only on 127.0.0.1 and its private IP. An 
unauthenticated query is rejected, while the app user authenticates with readWrite on 
travelmemory. The server reaches the internet only outbound through the NAT.

<img width="940" height="132" alt="image" src="https://github.com/user-attachments/assets/d27f698a-cea5-4fa7-aecb-aa33f230d271" />

<img width="940" height="73" alt="image" src="https://github.com/user-attachments/assets/5b645fd1-739b-4628-b367-0c01a09d9c17" />

<img width="940" height="114" alt="image" src="https://github.com/user-attachments/assets/4aa5ec9e-e188-4807-afaf-cbe969441be5" />

<img width="939" height="308" alt="image" src="https://github.com/user-attachments/assets/7568a612-b8b3-4d1b-89f6-0fd5ac1e4878" />

On the web server, the API runs under systemd, Nginx config is valid, port 80 is served by Nginx 
and 3001 by Node. The backend .env points at the DB server's private IP, and the frontend .env 
holds the public URL.

<img width="940" height="172" alt="image" src="https://github.com/user-attachments/assets/24925a0b-12a1-436a-ba78-475115de4da2" />

<img width="940" height="202" alt="image" src="https://github.com/user-attachments/assets/2e734afb-0de3-4224-b1d8-f5017f3cf606" />

<img width="940" height="150" alt="image" src="https://github.com/user-attachments/assets/30ddef07-f1f7-466c-9f06-9162e9022f17" />

<img width="940" height="499" alt="image" src="https://github.com/user-attachments/assets/8b112c6c-fce0-4101-94af-890a3136ccb8" />

<img width="939" height="308" alt="image" src="https://github.com/user-attachments/assets/5cb8aa81-70dc-491e-a1a3-935f3ceb43dc" />

# 8. Working application

<img width="940" height="499" alt="image" src="https://github.com/user-attachments/assets/84f8d2b9-9e7a-46de-a1d9-0c2aec8a15d3" />

<img width="940" height="474" alt="image" src="https://github.com/user-attachments/assets/22a20401-6b5e-4391-b1cc-3b97b77ba6cb" />

The React app is served at the web server's public IP and lists trips from the database

<img width="940" height="320" alt="image" src="https://github.com/user-attachments/assets/34f17cf8-a5e7-41e0-b953-0446a6616434" />

<img width="940" height="174" alt="image" src="https://github.com/user-attachments/assets/4f5b932c-d2b7-4bea-9db4-aafb34dccc1a" />

<img width="940" height="459" alt="image" src="https://github.com/user-attachments/assets/ee2fcfc3-2b5c-43b8-a547-fd4633ceaf14" />

<img width="940" height="339" alt="image" src="https://github.com/user-attachments/assets/f3680291-1139-4602-add0-037328bf1260" />

<img width="940" height="187" alt="image" src="https://github.com/user-attachments/assets/eae9509f-bccd-4480-99e6-93ac7705d3c9" />

# 9. Cleanup

<img width="940" height="329" alt="image" src="https://github.com/user-attachments/assets/f6717e75-efbf-4d3c-b526-f005c875bfe9" />

<img width="940" height="210" alt="image" src="https://github.com/user-attachments/assets/a1039b47-0144-4775-ac6d-f0ffa37cde3a" />

<img width="940" height="144" alt="image" src="https://github.com/user-attachments/assets/e45aeb2a-88d2-4ce9-970d-cd66ef5fd254" />



