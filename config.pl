################################################################################
# General server configuration
################################################################################

################################################################################
#   Directories
################################################################################

$Conf{config_dir}		= "$ENV{HOME}/scraper";

$Conf{run_dir}			= "$Conf{config_dir}/var/run";

$Conf{log_dir}			= "$Conf{config_dir}/var/log";

$Conf{tmp_dir}			= "$Conf{config_dir}/var/tmp";

$Conf{test_data}		= "$Conf{config_dir}/test";

################################################################################
# Files
################################################################################

$Conf{db_file}{proxy}		= "$Conf{run_dir}/proxy";
$Conf{db_file}{explorer}	= "$Conf{run_dir}/explorer.db";
$Conf{db_file}{scraper}		= "$Conf{run_dir}/scraper";
$Conf{db_file}{json_api}	= "$Conf{run_dir}/json_api.db";


$Conf{log_file}{proxy}		= "$Conf{log_dir}/proxy.log";
$Conf{log_file}{explorer}	= "$Conf{log_dir}/explorer.log";
$Conf{log_file}{scraper}	= "$Conf{log_dir}/scraper.log";
$Conf{log_file}{json_api}	= "$Conf{log_dir}/json_api.log";

################################################################################

$Conf{log_level}{proxy}		= 15;
$Conf{log_level}{explorer}	= 5;
$Conf{log_level}{scraper}	= 5;
$Conf{log_level}{json_api}	= 5;

################################################################################
# Array of proxy service targets
################################################################################

$Conf{proxy_targets}[0]	=  {
	uri	=> 'https://www.sslproxies.org/',
	start	=> 'scrape',
};
$Conf{proxy_targets}[1] = {
	uri	=> 'http://www.freeproxylists.com/elite.html',
	start	=> 'explore',
};

################################################################################
# Array of ip service targets
################################################################################

$Conf{ip_targets}[0] = {
	uri => 'https://www.astrill.com/what-is-my-ip-address.php',
};
$Conf{ip_targets}[1] = {
	uri => 'https://www.bnl.gov/itd/webapps/checkip.asp',
};
$Conf{ip_targets}[2] = {
	uri => 'https://www.etes.de/service/ip-check/',
};
$Conf{ip_targets}[3] = {
	uri => 'https://www.expressvpn.com/what-is-my-ip',
};
$Conf{ip_targets}[4] = {
	uri => 'https://hide.me/de/check',
};
$Conf{ip_targets}[5] = {
	uri => 'https://www.iplocation.net/find-ip-address',
};
$Conf{ip_targets}[6] = {
	uri => 'https://showip.net/',
};

###########################################################################
# Timeouts           
###########################################################################

$Conf{request_min_delay}{proxy}		= 0;
$Conf{request_min_delay}{explorer}	= 0;
$Conf{request_min_delay}{scraper}	= 0;

$Conf{request_max_delay}{proxy}		= 0;
$Conf{request_max_delay}{explorer}	= 2;
$Conf{request_max_delay}{scraper}	= 0;

$Conf{task_max_fails}{proxy}		= 3;
$Conf{task_max_fails}{explorer}		= 3;
$Conf{task_max_fails}{scraper}		= 0;

$Conf{task_max_retry}{proxy}		= 0;
$Conf{task_max_retry}{explorer}		= 5;
$Conf{task_max_retry}{scraper}		= 3;

$Conf{wake_interval}{proxy}		= 3 * 60;
$Conf{wake_interval}{explorer}		= 3 * 60;
$Conf{wake_interval}{scraper}		= 3 * 60;

$Conf{job_interval}{proxy}		= 8 * 60 * 60;
$Conf{job_interval}{explorer}		= 8 * 60 * 60;
$Conf{job_interval}{scraper}		= 8 * 60 * 60;

$Conf{begin_scraping}		= 2 * 24 * 60 * 60;

$Conf{update_age}{proxy} 		= -8 * 60 * 60;
$Conf{update_age}{explorer} 		= 0;
$Conf{update_age}{scraper} 		= 0;

################################################################################
# Host specific server configuration
################################################################################

my $user_name = $ENV{LOGNAME} || $ENV{USER} || getpwuid($<);

################################################################################
# Database access
################################################################################

if ( $user_name eq "hogh" ) {

	$Conf{db_host}	= "localhost";

	$Conf{db_name}	= "scraper";

	$Conf{db_user}	= "scraper";

	$Conf{db_pass}	= "scraper";
}
else {

	$Conf{db_host}	= "localhost";

	$Conf{db_name}	= "juergen_db_scraper";

	$Conf{db_user}	= "juergen_scraper";

	$Conf{db_pass}	= "most_secret";
}

###########################################################################
# Timezone
###########################################################################

if ( $user_name eq "hogh" ) {

	$Conf{time_zone}{local}		= 'Europe/Berlin';
	$Conf{time_zone}{standard}	= 'Europe/Berlin';
}
else {

	$Conf{time_zone}{local}		= 'America/Chicago';
	$Conf{time_zone}{standard}	= 'Europe/Berlin';
}

$Conf{seed_min} = 1000000;
$Conf{seed_max} = 1999999;
