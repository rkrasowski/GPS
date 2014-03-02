#!/usr/bin/perl
######################################## gpsTimeSet.pl ##################################
#                                                                                       #
#       Start GPS, get date and set computer date 					#
#       pin 21 ans 22 in P9                                                             #
#       by Robert J. Krasowski                                                          #
#       8/16/2013                                                                       #
#                                                                                       #
#########################################################################################

use strict;
use warnings;
use Device::SerialPort;
use Time::Local;


my $debug = 1;          # 0 - no debug, 1-is terminal STOUT, 2-STOUT to Log/main.log



# set pins in appropriate modes:
# Set UART 1
# Set Rx pin


debug("Check if GPS is ON .... ");
unless ( -d "/sys/class/gpio/gpio72" )
        {
                debug("GPS is not ON, will turn it ON");
                `sudo echo 72 > /sys/class/gpio/export`;
                `sudo echo out > /sys/class/gpio/gpio72/direction`;
                `sudo echo 1 > /sys/class/gpio/gpio72/value`;
        }

debug ("Now GPS is ON");

# set variables:
my $UNIXTime;
my $gpsTime = "";
my $gpsDate = "";
my $status = "";
my $timeSet;
my ($sec,$min,$hour,$day,$month,$year);
my $gpsTrialNum;

START:
$gpsTrialNum = 0;
# Activate serial connection:
my $PORT = "/dev/ttyO1";
my $serialData;

my $ob = Device::SerialPort->new($PORT) || die "Can't Open $PORT: $!";

$ob->baudrate(4800) || die "failed setting baudrate";
$ob->parity("none") || die "failed setting parity";
$ob->databits(8) || die "failed setting databits";
$ob->handshake("none") || die "failed setting handshake";
$ob->write_settings || die "no settings";
$| = 1;


open( GPS, "<$PORT" ) || die "Cannot open $PORT: $_";

debug("GPS port is open, ready to receive GPS data");
while ( $serialData = <GPS> )
         {
		
                if ($serialData =~ m/GPRMC/)
                        {

                                # print $serialData;

                                # split gps data by coma

                                my @gps = split (/\,/,$serialData);
                                my $gps;

                                ###########################################
                                # check if GPS data is valid 
                                # Status  A - data valid,  V - data not valid

                                $status = $gps[2];
				#$status = "V";
                                if ($status eq "A")
					{

                                		##########################################
                                		# get time
                                		$gpsTime = $gps[1];
                                		my @gpsTime = split(//,$gpsTime);
                                		$hour = $gpsTime[0].$gpsTime[1];
                                		$min = $gpsTime[2].$gpsTime[3];
                                		$sec = $gpsTime[4].$gpsTime[5];
                                		$gpsTime = $hour.":".$min.":".$sec;

                                		###########################################
                                		# get date
                                		$gpsDate = $gps[9];
                                		my @gpsDate = split(//,$gpsDate);
                                		$day = $gpsDate[0].$gpsDate[1];
                                		$month = $gpsDate[2].$gpsDate[3];
                                		$year = $gpsDate[4].$gpsDate[5];
                                		$gpsDate = $month."/".$day."/".$year;

                                		###########################################

						$timeSet = "$month"."$day"."$hour"."$min"."20"."$year"."."."$sec";

 		                               	debug("Status is $status");
                		                debug("gpsDate is $gpsDate");
                                		debug("gpsTime is $gpsTime");
						`date $timeSet`;
                                		debug("System time has been set to: $timeSet");
						goto AFTERTIMESET;

					}
				else	
					{	
						$gpsTrialNum = $gpsTrialNum +1;
						debug("Acquiring GPS satellite .. trial number $gpsTrialNum");
						sleep(1);
						if ($gpsTrialNum >= 10)
							{	
								goto FAILGPS;
							}
					}


	
                        }



        }

undef $ob;
close (GPS);

FAILGPS:
debug("Could't acquire GPS satellite ssignal, will try again later.");
sleep(1);
goto START;

AFTERTIMESET:
debug("Finished");

##################################### Subroutines ############################

sub debug 
	{
		my $text = shift;
		if ($debug == 2)
			{
				open LOG, '>>/home/ubuntu/Log/main.log' or die "Can't write to /home/ubuntu/Log/main.log: $!";
				select LOG;
				my $time = gmtime();
				my @arrayTime = split(/ /,$time);
				my $arrayTime;
				 $time = "$arrayTime[1]"."$arrayTime[2]"." ". "$arrayTime[3]".","."$arrayTime[5]"." "."$arrayTime[4]";

				
				print "$time: $text\n";
				select STDOUT;
				close (LOG);
			}
		if ($debug == 1)
			{
				my $time = gmtime();
				my @arrayTime = split(/ /,$time);
				my $arrayTime;
				 $time = "$arrayTime[1]"."$arrayTime[2]"." ". "$arrayTime[3]".","."$arrayTime[5]"." "."$arrayTime[4]";

				
				print "$time: $text\n";
			}

	}
