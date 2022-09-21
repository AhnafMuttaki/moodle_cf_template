Steps:
1. Run CF template
2. Login to EC2.
3. Run the following:
    sudo yum install git -y
    sudo git clone https://github.com/AhnafMuttaki/moodle_cf_template.git
    sudo chmod +x ./moodle_cf_template/install_moodle_in_amazon_linux.sh
    sudo ./moodle_cf_template/install_moodle_in_amazon_linux.sh
4. Change the wwwroot and DB endpoint in moodle/config.php