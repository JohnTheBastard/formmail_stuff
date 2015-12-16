WEBPM_PACKAGE_START(modules::finaid::HMCIds2pf,main)

################################################################################
## HMCids2pf.cgi
##
## Descr: Converts a list of user ids to a fixed-width file of fields
##        appropriate for loading into Powerfades.
## 
##        With this cgi, you can:
##           1. Submit a selection mask in order to generate a file.
##           2. Load a selection mask.
##           3. Save a selection mask
##           4. "Save As" a selection mask
################################################################################


our ($TargetDBS, %input, $TargetBack, $TargetCache, $TargetHelp, $TargetTitle, $TargetSubTitle, $TargetPageType, $Remote_id, $cweb, $db1, $num_params, %options);


sub main{

$|=1;

#local $SIG{ALRM} = sub { print "Test-Header: 1\n"; alarm 10; print STDERR "alarm\n"};
#alarm 10;
#print STDERR "Sleeping\n";
##sleep 300;
#print STDERR "Waking\n";


	#
	# The WEB-CGI-START(dbservice, title, *params) macro will set:
	#       $TargetDBS, $TargetTitle,$TargetUserType,$TargetUser,$TargetPageType
	#
	#	$Remote_id is set to the id number of $TargetUser from the database
	#       $num_params to the # of parameters. (*in) if *params is not specified
	#       $db1 (that is 'db' and the #1) to the DataClient object
	#
	WEBPM_CGI_START()

	## AC here on down
	use lib '/usr/local/www2/perl-libs';
	use Text::CSV_XS;
#	use CGI ':cgi-lib'; # so we can call Vars
	use CGI qw(:all delete_all escapeHTML);
	use CGI::Carp 'fatalsToBrowser';
	use DBI;
	use HTML::Template;
	use Data::Dumper;
	use PC_DBHelper;
	use Storable qw (freeze thaw);
	use Date::Calc qw(Date_to_Text Today);
	use DupCheck qw(name2sndx);

	## cgi object
	my $cgi = new CGI;

	## template obj
	my $tmpl = HTML::Template->new(
						  filename => 'hmcids2pf.tmpl',
						  die_on_bad_params => 0,
#						  path => [ '/usr/local/www2/tmpl/finaid/ids2pf' ],
						  path => [ 'WEB_SERVER_ROOTPATH/WEB_HTDOCS/modules/finaid' ],

## Turn it off ... field ids are getting passed on
#						  associate => $cgi,
						  case_sensitive => 1,
						  loop_context_vars => 1,
						  global_vars => 1
					  );

	##
	## Create portal-capable form action
	##
	local ($scrpt_name) = ($ENV{'SCRIPT_NAME'});
	$scrpt_name =~ s,^.*/(.*)$,$1,;
	$form_action = join('', $hrefpath, $scrpt_name, $postfix);



## FAKER DEFAULTS
#$cgi->param(-name=>'yr', -value=>2002);
#$cgi->param(-name => 'sess', -value=>'FA');
#$cgi->param(-name => 'prog', -value=>'UNDG');
#print STDERR "PARAMS:\n";
#print STDERR $cgi->param('yr'), "\n";
#print STDERR $cgi->param('sess'), "\n";
#print STDERR $cgi->param('prog'), "\n";

	##
	## CONNECT DB
	##
	my $db = $cweb->{'.cars'}{conf}{CARSDB};
	my $server = $cweb->{'.cars'}{conf}{INFORMIXSERVER};
	my $dsn = qq[dbi:Informix:$db\@$server];
	my $dbh = DBI->connect($dsn, undef,undef,{AutoCommit=>1,ChopBlanks=>1});
	$dbh || die DBI->errstr();
	my $dbhelper = new DBHelper($dbh);


	##
	## TEMPLATE GLOBALS
	##
	$tmpl->param( form_action=>$form_action,
	              portal_url => 'WEB_PORTAL_URL_POMONA'
					  );

	##
	## Get action
	##
	my $Action = $cgi->param('Action');


	## Remember the "show" fields
#	foreach my $s ( $cgi->param('Show')) {
#		$tmpl->param("isChecked$s" => "checked");
#	};

	##
	## Only allow 'get_file' from public
	##
	if ( (self_url() =~ /public/ ) && ( $Action !~ /get_file/)) {
			my $redirect = self_url();
			$redirect =~ s/public/faculty/;
			print redirect($redirect);
	};

	if (0) {
#	$cweb->cars_log_action('NODATA', $Remote_id, "$id:$sess:$yr");
	};

	##
	## Fix the Show param if this is from portal, which makes commas
	##
	if ( $cgi->param('Show') =~ /, /) {
		my $Show = $cgi->param('Show');
		my @Show;
		foreach my $var ( split(',', $Show)) {
			$var =~ s/\s*//g;
			push @Show, $var;
		};
		$cgi->param(-name => 'Show', -value => [@Show]);
	}

	##
	## And Away We Go ...
	##

	##
	## Loading Mask
	##
	if ( $Action eq 'load_mask') {

		## mask the chose
		my $mask_selection = $cgi->param('mask_selection');

		## talk to the template
		$tmpl->param('cur_selected_mask'=>$mask_selection,
              selection_masks => 
				     &get_mask_names($dbhelper,$ENV{REMOTE_USER},$mask_selection));

		## fetch the requested mask
		my $mask = &fetch_stored($dbhelper, $ENV{REMOTE_USER}, $mask_selection);

		## load it up
		&load_mask($mask, $tmpl);

		my $enr_stat_table = $dbhelper->select_lookuptable(
		                                       table=>'enr_stat_table',
	                                               cols => ['enrstat', 'txt'],
						       hashit => 1);
		$tmpl->param(enr_stat_table => $enr_stat_table);

	}

	##
	## Saving mask
	##
	elsif ( $Action eq 'save_mask') {
		my $storable = make_storable( {checkbox_ary => [$cgi->param('Show')],
		                               fieldid_ref  => &make_fieldid_ref($cgi)});
		&store_mask($dbhelper,$ENV{REMOTE_USER}, $cgi->param('cur_selected_mask'), $storable);
		$tmpl->param(
              selection_masks => 
				     &get_mask_names($dbhelper,$ENV{REMOTE_USER},$cgi->param('cur_selected_mask') ));

		## load the mask back up
		my $mask = &fetch_stored($dbhelper, 
		                         $ENV{REMOTE_USER}, 
										 $cgi->param('cur_selected_mask'));
		$tmpl->param('cur_selected_mask' => $cgi->param('cur_selected_mask'));
		&load_mask($mask, $tmpl);

		my $enr_stat_table = $dbhelper->select_lookuptable(
		                                       table=>'enr_stat_table',
	                                               cols => ['enrstat', 'txt'],
						       hashit => 1);
		$tmpl->param(enr_stat_table => $enr_stat_table);
	}

	##
	## Saving mask as
	##
	elsif ( $Action eq 'save_mask_as') {
		my $storable = make_storable( {checkbox_ary => [$cgi->param('Show')],
		                               fieldid_ref  => &make_fieldid_ref($cgi)});

		## store the mask
		&store_mask($dbhelper,$ENV{REMOTE_USER}, $cgi->param('save_as_name'), $storable);

		## talk to the template
		$tmpl->param(
              selection_masks => 
				     &get_mask_names($dbhelper,$ENV{REMOTE_USER},$cgi->param('save_as_name') ),
					cur_selected_mask => $cgi->param('save_as_name')
					  );

		my $enr_stat_table = $dbhelper->select_lookuptable(
		                                       table=>'enr_stat_table',
	                                               cols => ['enrstat', 'txt'],
						       hashit => 1);
		$tmpl->param(enr_stat_table => $enr_stat_table);

		## load the new mask back up
		my $mask = &fetch_stored($dbhelper, 
		                         $ENV{REMOTE_USER}, 
					 $cgi->param('save_as_name'));
		&load_mask($mask, $tmpl);


	}

	##
	## Deleting mask
	##
	elsif ( $Action eq 'delete_mask') {
		&delete_mask($dbhelper,$ENV{REMOTE_USER}, $cgi->param('mask_selection'));

		$tmpl->param(
			     selection_masks => 
			     &get_mask_names($dbhelper,$ENV{REMOTE_USER},$cgi->param('cur_selected_mask') ));


		my $enr_stat_table = $dbhelper->select_lookuptable(
		                                       table=>'enr_stat_table',
	                                               cols => ['enrstat', 'txt'],
						       hashit => 1);
		$tmpl->param(enr_stat_table => $enr_stat_table);

		## load the mask back up if its not the one we deleted
		if ($cgi->param('cur_selected_mask') ne $cgi->param('mask_selection')) {
			my $mask = &fetch_stored($dbhelper, 
			                         $ENV{REMOTE_USER}, 
						 $cgi->param('cur_selected_mask'));
			$tmpl->param('cur_selected_mask' => $cgi->param('cur_selected_mask'));
			&load_mask($mask, $tmpl);
		};
	}

	##
	## Running report
	##
	elsif ( $Action eq 'generate report') {

		## calc the date for the filename
		my $date = Date_to_Text(Today); 

		## uploading IDs from file
		my (@ids, @file_ids, $paste_box_str, $pasted_ids);

		my $uploadfile = $cgi->param('uploadfile');
		my $paste_box_str = $cgi->param('ids');

		##
		## Gather the ids
		##

		## wants the 'all adm_recs' predefined query
		if ( $cgi->param('prequery') eq 'all_admrecs' ) {
			my $id_ary = &get_all_admrecs($dbhelper, 
			                            $cgi->param('sess'), 
						    $cgi->param('yr'));
			push @ids, @$id_ary;
		}

		## wants the 'all enrolled' predefined query
		elsif ( $cgi->param('prequery') eq 'all_enrolled' ) {

			my $id_ary = &get_all_enrolled($dbhelper, 
			                            $cgi->param('sess'), 
						    $cgi->param('yr'));
			push @ids, @$id_ary;

		}

		## wants the 'enrstatequals' predefined query
		elsif ( $cgi->param('prequery') eq 'enrstatequals' ) {

			my $code = 'enrstatequals=' . $cgi->param('select_enrstat');
			my $id_ary = [$code];
			push @ids, @$id_ary;

		}
		## wants the 'selective_enrolled' predefined query
		elsif ( $cgi->param('prequery') eq 'selective_enrolled' ) {

			my @stats = $cgi->param('checkbox_enrstat');
			map {$_=qq['$_']} @stats;
			my $code = 'selective_enrolled='; ;
			my $str = join(',', @stats);
			$code .= $str;
			my $id_ary = [$code];
			push @ids, @$id_ary;

		}
		## wants the 'cofhe' predefined query
		elsif ( $cgi->param('prequery') eq 'cofhe' ) {
			my @stats = $cgi->param('checkbox_cofhe');
			map {$_=qq['$_']} @stats;
			my $code = 'cofhe='; ;
			my $str = join(',', @stats);
			$code .= $str;
			my $id_ary = [$code];
			push @ids, @$id_ary;

		}

		## pasted ids
		elsif ( $paste_box_str ) {
			$pasted_ids = &_parse_id_box($paste_box_str);
			foreach (@$pasted_ids) {
				push @ids, $_;
			};
		}
		elsif (  $uploadfile ) {
			while (<$uploadfile>) {
				s/[^0-9]//g;
				next if ! $_;
				push @ids, $_;
			};
		}
		else {
			warn "No ids\n";
		};


		## Create cache
		my $session = get_session_id();
		my $cache = get_cache_handle();
		$cache->set($session, [0, ""]);
	
		
		## simulate remembering the 'Show' checkbox fields in the cache
		my $vars = $cgi->Vars();
		foreach my $s ( $cgi->param('Show') ) {
			$vars->{"isChecked$s"} = "checked";
		};
	
		## save cgi state for "Return" and make_xls
		$cache->set("$session-vars", $vars);
		

		## fork
		if (my $pid = fork) {
			delete_all();
			param('session', $session);
			param('Action', 'get_cache');
my $qs = query_string();


			print redirect(self_url());
			$dbhelper->{dbh}->disconnect();
			exit 0;
		} 
		close STDOUT;
		$cache->set($session, [0, 'Working ...']);

		## child process needs to reconnect.
		$dbhelper->{dbh}->disconnect();
		$dbhelper->{dbh}=undef;
		$dbhelper->{dbh} = DBI->connect($dsn, undef,undef,{AutoCommit=>1,ChopBlanks=>1});
		$dbhelper->{dbh} || die DBI->errstr();


		##
		## Query the database
		##
		my $data_ary;
		eval {
	
			## Get the raw report data
			$data_ary = &get_report_data($dbhelper, 
#		                                $pasted_ids || [@file_ids],
		                                \@ids,
		                                $cgi->param('yr'),
						$cgi->param('sess'),
						$cgi->param('prog'),
						$cache, 
						$session,
						$vars);
		};

		## There were errors.
		my $errors;
		if ( $@) {
			$errors = "<font color=red><b>There was an error.</b> $@</font><br>$debug<p>";
		};
		
		## collect the "Show" checkboxes
		my @Show = $cgi->param('Show');
	
		## make the report
		$cache->set($session, [0,"Writing report ..."]);
		my $report = &make_report($data_ary, [@Show], &make_fieldid_ref($cgi),
			                          $cgi->param('make_xls') );


		## tell the cache we are done
		delete_all();
		param('session',$session);
		my $qs = query_string();
		my $return_url = qq[$form_action?$qs];

#		my $return_url = self_url();



		param('Action','get_file');
		my $qs = query_string();
		my $self_url = qq[$form_action?$qs];

		my $self_url = self_url();
		$self_url =~ s/faculty/public/;

		my $buf = qq[ <a href="$self_url">Retrieve File</a> &nbsp; | &nbsp; <a href="$return_url">Return</a> ];

	   $cache->set($session, [1,$errors. $buf]);
		$cache->set("${session}-file", $report);
		close STDOUT;
		exit 0;


##		print "Content-type: ms/excel\n";
#		print "Content-type: text/plain\n";
#		print "Content-Disposition: attachment; filename=$date PowerFaidsReport.dat\n\n";
#		print $report;
#		close(STDOUT);
#		exit(0);
	}

	##
	## Requesting Cache
	##
	elsif ( $Action eq 'get_cache') {

		my $session = param('session');
		my $cache = get_cache_handle();
		my $data = $cache->get($session);

#		print header;
		print $cweb->cars_start_page( $TargetBack, $TargetCache, $TargetHelp,
		$TargetTitle, $fullname, $TargetPageType);

		my $qs = "Action=$Action&session=$session";
		my $refresh_url = qq[$form_action?$qs];
		print start_html(-title => "Results",
				 ($data->[0] ? () : (-head =>
						     ["<meta http-equiv=refresh content=\"1; url=$refresh_url\">"])));


		##
		## Background job still running.
		##
		if ( $data->[0] != 1) {

			## template obj
			my $tmpl = HTML::Template->new(
						  path => [ '/usr/local/www2/tmpl' ],
						  filename => 'in_progress.tmpl',
						  die_on_bad_params => 0,
						  case_sensitive => 1,
						  loop_context_vars => 1,
						  global_vars => 1
					  );
			$tmpl->param(data => pre(escapeHTML($data->[1])));
			print $tmpl->output;
print $cweb->cars_end_page();
			close STDOUT;
			exit 0;
		}
		##
		## Background job finished.
		##
		else {
			print "<center>";
			print h2("Process complete");
			print $data->[1];
			print "<\/center>";
			print end_html;
		};

		print $cweb->cars_end_page();
		close STDOUT;
		exit;
   } 

	##
	## Requesting Report.
	##
	elsif ($Action eq 'get_file') {

		my $session = param('session');
		my $cache = get_cache_handle();
		my $report = $cache->get("${session}-file");
		my $vars = $cache->get("${session}-vars");


		## calc the date for the filename
#		my $date = Date_to_Text(Today); 
		my $ext;

		if ( $vars->{make_xls} == 1) {
			print "Content-type: ms/excel\n";
			$ext = "xls";
			print "Content-Disposition: attachment; filename=$date PowerFaidsReport.$ext\n\n";
			foreach my $line ( @$report ) {
				print "$line\n";
			};

		}
		else {
			print "Content-type: text/plain\n";
			$ext = "dat";
			print "Content-Disposition: attachment; filename=$date PowerFaidsReport.$ext\n\n";
			foreach my $line ( @$report ) {
				print "$line";
			};
		};
#		print $report;
		close(STDOUT);
		exit(0);
	}


	##
	## Default page
	##
	else {

		my $session = param('session');
		if ($session) {
		## Click "Return" on report page  -- load up the same fields from cache 
			my $cache = get_cache_handle();
			my $vars = $cache->get("${session}-vars");
			$tmpl->param(%$vars);
		};


		my $enr_stat_table = $dbhelper->select_lookuptable(table=>'enr_stat_table',
	                                               cols => ['enrstat',
						       'txt'],
						       hashit => 1);

		$tmpl->param( selection_masks => 
				     &get_mask_names($dbhelper,$ENV{REMOTE_USER}),
					     enr_stat_table => $enr_stat_table);

	};

## The End.
BAIL:
	## cars start page nonsense
	print $cweb->cars_start_page( $TargetBack, $TargetCache, $TargetHelp,
		$TargetTitle, $fullname, $TargetPageType);

	print $tmpl->output();

#print $cgi->Dump;
#print "<pre>",Dumper \%ENV, "</pre>";
	## cars end page nonsense
	$cweb->cars_end_page();

}


##############################################################################
## sub: get_mask_names
##
## Descr: Load's a user's saved masks
## Params: $ENV{REMOTE_USER}
## Returns: an array ref of hash refs:
##		[ {mask=> "Mask Name"}, ... ]
##############################################################################
sub get_mask_names {
	my ($dbhelper, $remote_user, $cur_selected_mask) = @_;

	my $ref = $dbhelper->select_multi(
		table	=> 'cucpfmasks_rec',
		cols  => ['mask_name'],
		where => {mask_user=>$remote_user},
		hashit => 1
	);
	
	foreach my $r ( @$ref ) {
		if ($r->{mask_name} eq $cur_selected_mask) {
			$r->{maskIsSelected} = 1;
		};
	};
	return $ref;
};

###############################################################################
## make_storable
##
## Descr: Takes an array ref, returns a storable hex string.
###############################################################################
sub make_storable {
	my ($ref) = @_;
#print STDERR "STORING:", Dumper $ref;
	my $bin = freeze($ref);
	my $hex = unpack("H*", $bin);

	return $hex;

};

###############################################################################
## store_mask
##
## Descr: Stores a mask hex string
## Params: $dbhelper, $user, $mask_name, $storable
###############################################################################
sub store_mask {
	my ($dbhelper, $user, $mask_name, $storable) = @_;

	## out with the old
	$dbhelper->delete( table => 'cucpfmasks_rec',
			   cols => { mask_user=> $user,
			   mask_name=> $mask_name } );

	## in with the new
	$dbhelper->insert(table=>'cucpfmasks_rec',
						  cols => { mask_user=> $user,
							    mask_name=> $mask_name,
							    mask_text=> $storable } );

};

###############################################################################
## delete_mask
##
## Descr: Deletes a mask
## Params: $dbhelper, $user, $mask_name, 
###############################################################################
sub delete_mask {
	my ($dbhelper, $user, $mask_name) = @_;

	## out with the old
	$dbhelper->delete( table => 'cucpfmasks_rec',
			   cols => { mask_user=> $user,
		           mask_name=> $mask_name } );

	return 1;
};


###############################################################################
## fetch_stored
##
## Descr: Fetches a search mask from db
## Params: $dbhelper, $user, $mask_name
###############################################################################
sub fetch_stored {
	my ($dbhelper, $mask_user, $mask_name) = @_;

	my ($hex) = $dbhelper->simple_select(table=> 'cucpfmasks_rec',
	                         cols => ['mask_text'],
				 where => {mask_name=>$mask_name,
				 mask_user=>$mask_user});
                            


	my $bin= pack("H*", $hex);

	my $thawed = thaw($bin);
	return $thawed;

};


###############################################################################
## load_mask
##
## Descr: Stores a mask hex string
## Params: $dbhelper, $user, $mask_name, $storable
###############################################################################
sub load_mask {
	my ($mask,$tmpl) = @_;


	## remember the 'Show' checkbox fields
	foreach my $s ( @{ $mask->{checkbox_ary} || $mask } ) {
		$tmpl->param("isChecked$s" => "checked");
	};

	## remember the 'fieldID' textboxes
	while (my ($field, $value) = each %{ $mask->{fieldid_ref} } ) {
		$tmpl->param("$field" => "$value");
	};

};

###############################################################################
## field
##
## Descr:  Used below, in make_report to generate the string $fmt, one variable
##         at a time.
## Params: Takes one integer (the width of the variable in question).
##         
## -jhearn 4/11/07
###############################################################################

sub field {
  my $length = shift;
  if ($length == 0) {
    return "";
  } else {
    my $ret="@";
    for (1..$length-1) {
      $ret.=">";
    }
    return $ret;
  }
}

###############################################################################
## make_report
##
## Descr: Makes a fixed-width field report
## Params: $data_ary -- the raw report data (an arrayref of hashrefs)
##         $Show     -- an arrayref of the cgi Show checkboxes
###############################################################################
sub make_report {
	my ($data_ary, $Show, $fieldid_ref, $make_xls) = @_;

	## write final to here
	my @master;

	##
	## blot out the fields we didnt use
	##

	##
	## In case we're doing a spreadsheet
	##
	my $csv = Text::CSV_XS->new({sep_char=>"\t"});
	if ($make_xls) {
		my $status = $csv->combine(@{ &make_col_headers() });
		my $line   = $csv->string;
		push @master, $line;
	}

	## iterate each fully defined id
	foreach my $data_ref (@$data_ary) {
		my $masked_ref = {};
		my $masked_field_ids = {};
		my $field_ids  = {

			plan_grad_yr => $fieldid_ref->{fieldIDplan_grad_yr} || 2710,
			adm_yr       => $fieldid_ref->{fieldIDadm_yr}       || 2505,
			cur_enr_date => $fieldid_ref->{fieldIDcur_enr_date} || 2801, #2507
			percentile => $fieldid_ref->{fieldIDpercentile}     || 2706,
			reg_hrs      => $fieldid_ref->{fieldIDreg_hrs}      || 2708,
			hs_rank      => $fieldid_ref->{fieldIDhs_rank}      || 2718,
			hs_size      => $fieldid_ref->{fieldIDhs_size}      || 2719,
			birth_date   => $fieldid_ref->{fieldIDbirth_date}   || 2501,
			plan_enr_yr  => $fieldid_ref->{fieldIDplan_enr_yr}  || 4250,
			score1       => $fieldid_ref->{fieldIDscore1}       || 2702,
			score2       => $fieldid_ref->{fieldIDscore2}       || 2703,
			score3       => $fieldid_ref->{fieldIDscore3}       || 2704,
			score5       => $fieldid_ref->{fieldIDscore5}       || 2705,
			decsn_rank   => $fieldid_ref->{fieldIDdecsn_rank}   || 2801,
			pmt_terms    => $fieldid_ref->{fieldIDpmt_terms}    || 2844,
			sex          => $fieldid_ref->{fieldIDsex}          || 2843,
			nm_applicant => $fieldid_ref->{fieldIDnm_applicant} || 0,
			adm_prog     => $fieldid_ref->{fieldIDadm_prog}     || 0,
			res_asst     => $fieldid_ref->{fieldIDres_asst}     || 2812,
			plan_enr_sess => $fieldid_ref->{fieldIDplan_enr_sess} || 4121,
			non_tally => $fieldid_ref->{fieldIDnon_tally}       || 4123,
			resrc => $fieldid_ref->{fieldIDresrc}               || 4103,
			adm_citz     => $fieldid_ref->{fieldIDadm_citz}     || 2813,
			ethnic_code1 => $fieldid_ref->{fieldIDethnic_code1} || 4109,
			ethnic_code2 => $fieldid_ref->{fieldIDethnic_code2} || 4110,
			ethnic_code3 => $fieldid_ref->{fieldIDethnic_code3} || 4113,
			ethnic_code4 => $fieldid_ref->{fieldIDethnic_code4} || 4114,
			fa           => $fieldid_ref->{fieldIDfa}           || 4119,
			decsn  => $fieldid_ref->{fieldIDdecsn}              || 4116,
			early_decsn  => $fieldid_ref->{fieldIDearly_decsn}  || 2816,
			fa_enr_stat  => $fieldid_ref->{fieldIDfa_enr_stat}  || 2851,
			fa_intend_hsg => $fieldid_ref->{fieldIDfa_intend_hsg} || 2816,
			hs_st        => $fieldid_ref->{fieldIDhs_st}       || 2811,
			odec         => $fieldid_ref->{fieldIDodec}         || 2812,
			sp_enr_stat  => $fieldid_ref->{fieldIDsp_enr_stat}  || 2852,
			sp_intend_hsg => $fieldid_ref->{fieldIDsp_intend_hsg} || 2817,
			cl           => $fieldid_ref->{fieldIDcl}           || 2836,
			adm_sess     => $fieldid_ref->{fieldIDadm_sess}     || 2839,
			ethnic_code  => $fieldid_ref->{fieldIDethnic_code}  || 4125,
			first_gen    => $fieldid_ref->{fieldIDfirst_gen}   || 4135,
			cofhe        => $fieldid_ref->{fieldIDcofhe}       || 2837,
			cofhe_eth    => $fieldid_ref->{fieldIDcofhe_eth}   || 4137,
			
		};

## 			total_score   => $fieldid_ref->{fieldIDtotal_score}  || 2704,
##			cum_gpa      => $fieldid_ref->{fieldIDcum_gpa}      || 2703,
		


		## only show the fields user checked.
		foreach my $show (@$Show) {

			## Pretty important to make the html "Show" name is the same as the 
			## hashref key!
			$masked_ref->{$show} = $data_ref->{$show};
			$masked_field_ids->{$show} = $field_ids->{$show};
		};

		##
		## The order of output
		##
		
		#-------------------------------------------#
		# The code below was horrible, so I rewrote #
		# it to be more readible and maintainable.  #
		#   -jhearn 4/11/07                         #
		#-------------------------------------------#

		my (@vars,$fmt);

		push @vars, $masked_ref->{ss_no};              $fmt.=field(9); 
		push @vars, $masked_ref->{id};                 $fmt.=field(10);
		push @vars, $masked_ref->{lname};              $fmt.=field(16);
		push @vars, $masked_ref->{fname};              $fmt.=field(11);
		push @vars, $masked_ref->{mi};                 $fmt.=field(1);
		push @vars, $masked_ref->{perm_line1};         $fmt.=field(30);
		push @vars, $masked_ref->{perm_line2};         $fmt.=field(30);
		push @vars, $masked_ref->{perm_city};          $fmt.=field(17);
		push @vars, $masked_ref->{perm_st};            $fmt.=field(2);
		push @vars, $masked_ref->{perm_ctry};          $fmt.=field(15);
		push @vars, $masked_ref->{perm_zip};           $fmt.=field(5);
		push @vars, $masked_ref->{perm_zip4};          $fmt.=field(4);
		push @vars, $masked_ref->{perm_phone};         $fmt.=field(10);
		push @vars, 'C';                               $fmt.=field(1);  # seconday addr destination
		push @vars, undef;                             $fmt.=field(8);  # secondary date of expiration
		push @vars, $masked_ref->{camp_line1};         $fmt.=field(30);
		push @vars, $masked_ref->{camp_line2};         $fmt.=field(30);
		push @vars, undef;                             $fmt.=field(17); # campus city
		push @vars, undef;                             $fmt.=field(2);  # campus st
		push @vars, undef;                             $fmt.=field(15); # campus country
		push @vars, undef;                             $fmt.=field(5);  # campus zip
		push @vars, undef;                             $fmt.=field(4);  # campus zip+4
		push @vars, $masked_ref->{camp_phone_ext};     $fmt.=field(10);
		push @vars, $masked_ref->{eml1};               $fmt.=field(40);
		push @vars, undef;                             $fmt.=field(8);  # birth date
		push @vars, undef;                             $fmt.=field(2);  # state of legal residence
		push @vars, undef;                             $fmt.=field(1);  # residency
		push @vars, undef;                             $fmt.=field(1);  # housing
		push @vars, undef;                             $fmt.=field(6);  # formerly $masked_ref->{exp_grad_date}
		push @vars, $masked_ref->{adm_stat};           $fmt.=field(1);
		push @vars, undef;                             $fmt.=field(1);  # citizenship
		push @vars, undef;                             $fmt.=field(1);  # 2nd back degree
		push @vars, undef;                             $fmt.=field(1);  # title/gender
		push @vars, undef;                             $fmt.=field(1);  # vet status
		push @vars, $masked_ref->{hs_gpa};             $fmt.=field(3);
		push @vars, undef;                             $fmt.=field(3);  # college gpa
		push @vars, $masked_ref->{sat_verbal};         $fmt.=field(2);
		push @vars, $masked_ref->{sat_math};           $fmt.=field(2);
		push @vars, $masked_ref->{act_comp};           $fmt.=field(2);
		push @vars, undef;                             $fmt.=field(1);  # satisfactory progress
		push @vars, undef;                             $fmt.=field(6);  # enrollment date
		push @vars, undef;                             $fmt.=field(4);  # credits/hours
		push @vars, undef;                             $fmt.=field(2);  # version
		push @vars, $masked_ref->{prog};               $fmt.=field(2);
		push @vars, $masked_ref->{major1};             $fmt.=field(4);
		push @vars, $masked_ref->{trnsfr};             $fmt.=field(1);
		push @vars, undef;                             $fmt.=field(3);  # counselor
		push @vars, $masked_ref->{lv_date};            $fmt.=field(8);
		push @vars, $masked_ref->{exp_grad_date};      $fmt.=field(8);
		push @vars, $masked_ref->{enr_date};           $fmt.=field(8);
		push @vars, undef;                             $fmt.=field(310); # col 405-714
		push @vars, $masked_field_ids->{plan_grad_yr}; $fmt.=field(6);
		push @vars, $masked_ref->{plan_grad_yr};       $fmt.=field(8);
		push @vars, $masked_field_ids->{adm_yr};       $fmt.=field(6);
		push @vars, $masked_ref->{adm_yr};             $fmt.=field(8);
		push @vars, $masked_field_ids->{cum_gpa};      $fmt.=field(6);
		push @vars, $masked_ref->{cum_gpa};            $fmt.=field(8);
		push @vars, $masked_field_ids->{cur_enr_date}; $fmt.=field(6);
		push @vars, $masked_ref->{cur_enr_date};       $fmt.=field(8);
		# push @vars, undef;                           $fmt.=field(6);   # sdec field ID - HMC removed
		# push @vars, undef;                           $fmt.=field(8);   # sdec - HMC removed
		push @vars, $masked_field_ids->{percentile};   $fmt.=field(6);   # HMC add
		push @vars, $masked_ref->{percentile};         $fmt.=field(8);   # HMC add
		push @vars, $masked_field_ids->{reg_hrs};      $fmt.=field(6);
		push @vars, $masked_ref->{reg_hrs};            $fmt.=field(8);
		push @vars, $masked_field_ids->{hs_rank};      $fmt.=field(6);
		push @vars, $masked_ref->{hs_rank};            $fmt.=field(8);
		push @vars, $masked_field_ids->{hs_size};      $fmt.=field(6);
		push @vars, $masked_ref->{hs_size};            $fmt.=field(8);
		push @vars, $masked_field_ids->{birth_date};   $fmt.=field(6);
		push @vars, $masked_ref->{birth_date};         $fmt.=field(8);
		push @vars, $masked_field_ids->{plan_enr_yr};  $fmt.=field(6);
		push @vars, $masked_ref->{plan_enr_yr};        $fmt.=field(8);
		push @vars, $masked_field_ids->{score1};       $fmt.=field(6);   # HMC add
		push @vars, $masked_ref->{score1};             $fmt.=field(8);   # HMC add
		push @vars, $masked_field_ids->{score2};       $fmt.=field(6);   # HMC add
		push @vars, $masked_ref->{score2};             $fmt.=field(8);   # HMC add
		push @vars, $masked_field_ids->{score3};       $fmt.=field(6);   # HMC add
		push @vars, $masked_ref->{score3};             $fmt.=field(8);   # HMC add
		push @vars, $masked_field_ids->{score5};       $fmt.=field(6);   # HMC add
		push @vars, $masked_ref->{score5};             $fmt.=field(8);   # HMC add
		push @vars, $masked_field_ids->{decsn_rank};   $fmt.=field(6);   # HMC add
		push @vars, $masked_ref->{decsn_rank};         $fmt.=field(8);   # HMC add
		# push @vars, undef;                           $fmt.=field(420);  # cols 855-1274 - HMC removed
		push @vars, undef;                             $fmt.=field(350); # cols 939-1274 - HMC comment Date/Int ends
		push @vars, $masked_field_ids->{pmt_terms};    $fmt.=field(6);
		push @vars, $masked_ref->{pmt_terms};          $fmt.=field(1);
		push @vars, $masked_field_ids->{sex};          $fmt.=field(6);
		push @vars, $masked_ref->{sex};                $fmt.=field(1);
		push @vars, $masked_field_ids->{nm_applicant}; $fmt.=field(6);
		push @vars, $masked_ref->{nm_applicant};       $fmt.=field(1);
		push @vars, $masked_field_ids->{adm_prog};     $fmt.=field(6);
		push @vars, $masked_ref->{adm_prog};           $fmt.=field(1);
		push @vars, $masked_field_ids->{res_asst};     $fmt.=field(6);
		push @vars, $masked_ref->{res_asst};           $fmt.=field(1);
		# push @vars, undef;                           $fmt.=field(0);   # old adm_sess field id - HMC removed
		# push @vars, undef;                           $fmt.=field(0);   # old adm_sess - HMC removed
		# push @vars, undef;                           $fmt.=field(0);   # cols 1324-1414 - HMC removed
		# push @vars, undef;                           $fmt.=field(0);   # old class standing field id - HMC removed
		push @vars, $masked_field_ids->{decsn};        $fmt.=field(6);   # HMC add
		push @vars, $masked_ref->{decsn};              $fmt.=field(1);   # HMC add
		push @vars, $masked_field_ids->{plan_enr_sess};$fmt.=field(6);   # HMC add
		push @vars, $masked_ref->{plan_enr_sess};      $fmt.=field(1);   # HMC add
		push @vars, $masked_field_ids->{non_tally};    $fmt.=field(6);   # HMC add
		push @vars, $masked_ref->{non_tally};          $fmt.=field(1);   # HMC add
		push @vars, $masked_field_ids->{resrc};        $fmt.=field(6);   # HMC add
		push @vars, $masked_ref->{resrc};              $fmt.=field(1);   # HMC add
		# push @vars, undef;                           $fmt.=field(91);  # cols 1324-1414
		push @vars, undef;                             $fmt.=field(77);  # cols 1338-1414
		push @vars, $masked_field_ids->{adm_citz};     $fmt.=field(6);
		push @vars, $masked_ref->{adm_citz};           $fmt.=field(5);
		push @vars, $masked_field_ids->{ethnic_code1}; $fmt.=field(6);
		push @vars, $masked_ref->{ethnic_code1};       $fmt.=field(5);
		push @vars, $masked_field_ids->{ethnic_code2}; $fmt.=field(6);
		push @vars, $masked_ref->{ethnic_code2};       $fmt.=field(5);
		push @vars, $masked_field_ids->{ethnic_code3}; $fmt.=field(6);
		push @vars, $masked_ref->{ethnic_code3};       $fmt.=field(5);
		push @vars, $masked_field_ids->{ethnic_code4}; $fmt.=field(6);
		push @vars, $masked_ref->{ethnic_code4};       $fmt.=field(5);
		push @vars, $masked_field_ids->{fa};           $fmt.=field(6);
		push @vars, $masked_ref->{fa};                 $fmt.=field(5);
		push @vars, $masked_field_ids->{early_decsn};  $fmt.=field(6);
		push @vars, $masked_ref->{early_decsn};        $fmt.=field(5);
		push @vars, $masked_field_ids->{fa_enr_stat};  $fmt.=field(6);
		push @vars, $masked_ref->{fa_enr_stat};        $fmt.=field(5);
		push @vars, $masked_field_ids->{fa_intend_hsg};$fmt.=field(6);
		push @vars, $masked_ref->{fa_intend_hsg};      $fmt.=field(5);
		push @vars, $masked_field_ids->{hs_st};        $fmt.=field(6);
		push @vars, $masked_ref->{hs_st};              $fmt.=field(5);
		push @vars, $masked_field_ids->{odec};         $fmt.=field(6);
		push @vars, $masked_ref->{odec};               $fmt.=field(5);
		push @vars, $masked_field_ids->{total_score};  $fmt.=field(6);
		push @vars, $masked_ref->{total_score};        $fmt.=field(5);
		push @vars, $masked_field_ids->{sp_enr_stat};  $fmt.=field(6);
		push @vars, $masked_ref->{sp_enr_stat};        $fmt.=field(5);
		push @vars, $masked_field_ids->{sp_intend_hsg};$fmt.=field(6);
		push @vars, $masked_ref->{sp_intend_hsg};      $fmt.=field(5);
		push @vars, $masked_field_ids->{cl};           $fmt.=field(6);
		push @vars, $masked_ref->{cl};                 $fmt.=field(5);
		push @vars, $masked_field_ids->{adm_sess};     $fmt.=field(6);
		push @vars, $masked_ref->{adm_sess};           $fmt.=field(5);
		push @vars, $masked_field_ids->{ethnic_code};  $fmt.=field(6);
		push @vars, $masked_ref->{ethnic_code};        $fmt.=field(5);
		push @vars, $masked_field_ids->{first_gen};    $fmt.=field(6);
		push @vars, $masked_ref->{first_gen};          $fmt.=field(5);
		push @vars, $masked_field_ids->{cofhe};        $fmt.=field(6);
		push @vars, $masked_ref->{cofhe};              $fmt.=field(5);
		push @vars, $masked_field_ids->{cofhe_eth};    $fmt.=field(6);
		push @vars, $masked_ref->{cofhe_eth};          $fmt.=field(5);
	        push @vars, undef;                             $fmt.=field(6);
		push @vars, undef;                             $fmt.=field(50);
	        push @vars, undef;                             $fmt.=field(6);
		push @vars, undef;                             $fmt.=field(50);
		push @vars, $masked_ref->{citz};               $fmt.=field(15);
		push @vars, " ";                               $fmt.=field(1);   # ??? aid status?
		push @vars, " ";                               $fmt.=field(98);  # ??? this is suspect
		push @vars, $masked_ref->{athletic};           $fmt.=field(2);
		push @vars, undef;                             $fmt.=field(138);

		if ($make_xls) {
		  my $status = $csv->combine(@vars);
		  my $line   = $csv->string;
		  push @master, $line;
		} else {
		  ##
		  ## make the line
		  ##
		  my $string = $fmt;
		  
		  
		#-------------------------------------------#
		# My changes end here.                      #
		#   -jhearn 4/11/07                         #
		#-------------------------------------------#
		
		  
		  ## pad it
		  while (length($string)<2000) {
		    $string.=' ';
		  };
		  push @master, $string;

		  
		};
	      };

#	my $report_txt = join(chr(13).chr(10), @master);
#	my $report_txt = join("\n", @master);

return [@master];
	my $report_txt;
	if ($make_xls) {
		$report_txt = join("\n", @master);
	}
	else {
		$report_txt = join('', @master);
	};
	return $report_txt;
};


###############################################################################
## get_report_data
##
## Descr: Wrapper to get_id_data_fast
## Params: $dbhelper, $id
## Returns: an array ref of hash refs.
###############################################################################
sub get_report_data {
	my ($dbhelper,$id_ary, $yr, $sess, $prog, $cache, $session, $show) = @_;

	## verify params
	if (! ($dbhelper && $id_ary) ) {
		warn "Invalid params to get_report_data";
		return undef;
	};


	my @results;
	my $count=0;
	my $total = scalar @$id_ary;
	my $time=time();

	my $buf = "Querying database ...\n";
	$cache->set($session, [0,$buf]);

	foreach (@$id_ary) {
		next if ! $_;
		$count++;
		if ($count > 1) {
			$cache->set($session, [0,"$buf $count of $total"]);
		};
#		$cache->set($session, [0,"$count of $total"]);
#		my $data_ary = &get_id_data_fast($dbhelper,$_, $yr, $sess, $prog);
		my $data_ary = &get_id_data_faster($dbhelper, $_, $yr, $sess, $prog, $cache, $session, $buf, $show);
		push @results, @$data_ary;
	};

#print STDERR "NUM results=", scalar @results, "\n";

#	print STDERR "Took ", time() - $time, "\n";
	return [@results];

};





###############################################################################
## _get_camp_phone_ext
##
## Descr: Pulls CX PowerFaids data
## Params: $dbhelper, $id
###############################################################################
sub _get_camp_phone_ext {
	my ($dbh, $id, $yr, $sess) = @_;

	if (! ($dbh && $id && $yr && $sess ) ) {
		warn "Invalid parms to _get_camp_phone_ext";
		return undef;
	};

	my $sql = "SELECT facil_table.phone_ext ".
	          "FROM facil_table, stu_serv_rec ".
				 "WHERE stu_serv_rec.id=? AND ".
				 "stu_serv_rec.campus=facil_table.campus AND ".
				 "stu_serv_rec.bldg=facil_table.bldg AND ".
				 "stu_serv_rec.room=facil_table.room AND ".
				 "stu_serv_rec.yr=? AND stu_serv_rec.sess=? ";
	my $sth = $dbh->prepare($sql);
	my $rv = $sth->execute($id,$yr, $sess );
	my ($camp_phone_ext) = $sth->fetchrow_array();
	return $camp_phone_ext;
	
};


###############################################################################
## _parse_id_box
##
## Descr: Parsed the "submit ids" box into an array. Splits on white space.
## Params: $box -- the content of the $cgi->param('ids') text area.
###############################################################################
sub _parse_id_box {
	my ($box) = @_;
#warn "box=$box\n";	
	my @ids = split(/\s+/,$box);
#warn "SPlist ids: ",Dumper \@ids;

	## taint check - allow integers only
	map {s/[^0-9]//g} @ids;

	return [@ids];
};

###############################################################################
## swrite
##
## Descr: print the fixed width line (from p.241)
## Params: $format -- the report line format
##         @       -- the args to print
###############################################################################
sub swrite {
	my $format = shift;
	$^A = "";
	formline($format,@_);
	return $^A;

};


sub make_fieldid_ref {
	my ($cgi) = @_;
	my $ref = {};
	foreach my $key (grep /fieldID/, $cgi->param) {
	$ref->{$key} = $cgi->param($key);
	};

	return $ref;
};


sub get_all_admrecs {
	my ($dbhelper, $sess, $yr) = @_;

	return ['all_admrecs'];
	my $sql = "select id from adm_rec where plan_enr_sess=? and plan_enr_yr=?";
	my $sth = $dbhelper->{dbh}->prepare($sql);
	$sth->execute($sess, $yr);
	while ( my ($id) = $sth->fetchrow_array()) {
		push @results, $id;
	};
	return [@results];

};

sub get_all_enrolled {
	my ($dbhelper, $sess, $yr) = @_;
return ['all_enrolled'];
	my $sql = qq[select id from sbcust_rec where sess=? and yr=? and enr_stat in ('C','E','P','I','B','A','AN')];
	my $sth = $dbhelper->{dbh}->prepare($sql);
	$sth->execute($sess, $yr);
	while ( my ($id) = $sth->fetchrow_array()) {
		push @results, $id;
	};

	return [@results];

};


   sub get_session_id {
       require Digest::MD5;

       Digest::MD5::md5_hex(Digest::MD5::md5_hex(time().{}.rand().$$));
}

sub get_file_data {
	my ($session) = @_;
	return "This is file data";
};

   sub get_cache_handle {
     require Cache::FileCache;

     Cache::FileCache->new
         ({
     namespace => 'powerfaids',
     username => 'nobody',
    default_expires_in => '30 minutes',
     auto_purge_interval => '4 hours',
          });
   }

   
###############################################################################
## get_id_data_faster
##
## Descr: Pulls CX PowerFaids data, built to handle bulk querying OR single 
##        id queries.
## Params: $dbhelper, $id
###############################################################################
sub get_id_data_faster {
	my ($dbhelper,$id, $yr, $sess, $prog, $cache, $session, $buf, $show) = @_;

	## verify params
	if (! ($dbhelper && $id && $yr && $sess && $prog) ) {
		warn "Invalid params to get_id_data_fast";
		return undef;
	};


## PC CHANGE 10/20/04 -- changing below line to NOT concat line2 or 3.
## if 2 or 3 are null, it blanks the whole thing
##	eml1.line1 || eml1.line2 || eml1.line3 email,

	my $sql = <<END;
SELECT
	id_rec.ss_no,
	id_rec.id,
	id_rec.fullname,

	perm.line1,
	perm.line2,
	perm.city,
	perm.ctry,
	perm.zip,
	perm.phone,
	perm.st,

	camp.line1 camp_line1,
	camp.line2 camp_line2,

	eml1.line1 email,

	prog_enr_rec.plan_grad_yr,
	prog_enr_rec.plan_grad_sess,
	prog_enr_rec.adm_stat,
	prog_enr_rec.enr_date,
	prog_enr_rec.prog,
	prog_enr_rec.major1,
	prog_enr_rec.lv_date,
	prog_enr_rec.adm_yr,
	prog_enr_rec.adm_sess,

	adm_rec.cur_enr_date,
	adm_rec.fa,
	adm_rec.decsn,
	adm_rec.early_decsn,
	adm_rec.trnsfr,
	adm_rec.enrstat,
	adm_rec.plan_enr_yr,
	adm_rec.first_gen,
	adm_rec.plan_enr_sess,
	adm_rec.stutype,
	
	adm_ethnic_rec.ethnic_code1,
	adm_ethnic_rec.ethnic_code2,
	adm_ethnic_rec.ethnic_code3,
	adm_ethnic_rec.ethnic_code4,

	profile_rec.citz,
	profile_rec.sex,
	profile_rec.ethnic_code,
	profile_rec.birth_date,

	stu_serv_rec.res_asst,

	stu_acad_rec.reg_hrs,
	stu_acad_rec.cl,

	ed_rec.gpa,
	ed_rec.rank,
	ed_rec.cl_size,
	ed_rec.percentile,
	
	sat.score1,
	sat.score2,
	sat.score3,
	math.score5,

	reader_rec.decsn_rank,
	reader_rec.non_tally,

	ctc_rec.resrc


FROM 
	id_rec,
	OUTER aa_rec perm,
	OUTER aa_rec camp,
	OUTER aa_rec eml1,
	OUTER prog_enr_rec,
	OUTER adm_rec,
	OUTER adm_ethnic_rec,
	OUTER profile_rec,
	OUTER stu_serv_rec,
	OUTER stu_acad_rec,
	OUTER ed_rec,
	OUTER highscore_rec sat,
	OUTER highscore_rec math,
	OUTER reader_rec,
	OUTER ctc_rec

WHERE

END

	my @vars;

	## 'all_enrolled' predefined query
	if ( $id eq 'all_enrolled') {
		$buf .= "Predefined query all enrolled ...";
		$cache->set($session, [0,$buf]);
		$sql .= qq[ id_rec.id IN (select id from sbcust_rec where sess='$sess' and yr=$yr and enr_stat in ('C','E','P','I','B','A','AN')) AND ];
#print STDERR "SQL=$sql\n";
#		$sql .= qq[ id_rec.id IN (select id from sbcust_rec where sess='$sess' and yr=$yr and enr_stat in ('C')) AND ];

	}

	## 'all_admrecs' predefined query
	elsif ( $id eq 'all_admrecs') {
		$buf .= "\nPredefined query all admrecs ...";
		$cache->set($session, [0,$buf]);
		$sql .= qq[ id_rec.id IN (select id from adm_rec where plan_enr_sess='$sess' and plan_enr_yr=$yr) AND ];
	}

	## 'enrstatequals' predefined query
	elsif ( $id =~ 'enrstatequals') {
		my ($enrstat) = $id =~ /=(.*)/;
		$buf .= "Predefined query enrstat equals $enrstat ...";
		$cache->set($session, [0,$buf]);
		$sql .= qq[ id_rec.id IN (select id from adm_rec where plan_enr_sess='$sess' and plan_enr_yr=$yr and enrstat in ('$enrstat')) AND ];

	}
	## 'selective_enrolled' predefined query
	elsif ( $id =~ 'selective_enrolled') {
		$buf .= "Predefined query selective enrolled ...";
		$cache->set($session, [0,$buf]);
		## selective_enrolled='X','Y','Z'
		my ($enr_stat) = $id =~ /=(.*)/;
		$sql .= qq[ id_rec.id IN (select id from sbcust_rec where sess='$sess' and yr=$yr and enr_stat in ($enr_stat)) AND ];
#print STDERR "SQL=$sql\n";

	}
	## 'cofhe' predefined query
	elsif ( $id =~ 'cofhe') {
		$buf .= "Predefined query cofhe ...";
		$cache->set($session, [0,$buf]);
		## cofhe='N','Y'
		my ($cofhe) = $id =~ /=(.*)/;
		$sql .= qq[ id_rec.id IN ( select pcadmloc_rec.id from pcadmloc_rec,adm_rec where adm_rec.id=pcadmloc_rec.id and adm_rec.plan_enr_yr=$yr and adm_rec.plan_enr_sess="$sess" and pcadmloc_rec.prog='$prog' and pcadmloc_rec.cofhe in ($cofhe)) AND ];
	}

	
	## id
	else {
		$sql .= "id_rec.id=? AND ";
		push @vars, $id;
	}


	$sql .= <<END;

	perm.id=id_rec.id AND
	perm.aa='PERM' AND
	( perm.end_date is null or perm.end_date > today or perm.end_date = '')
	AND (perm.beg_date is null or perm.beg_date < today) AND

	camp.id=id_rec.id AND
	camp.aa='CAMP' AND
	( camp.end_date is null or camp.end_date > today or camp.end_date = '')
	AND (camp.beg_date is null or camp.beg_date < today) AND

	eml1.id=id_rec.id AND
	eml1.aa='EML1' AND

	id_rec.id=prog_enr_rec.id AND
	prog_enr_rec.prog=? AND

	id_rec.id=adm_rec.id AND
	adm_rec.prog=? AND

	id_rec.id=adm_ethnic_rec.id AND
	
	id_rec.id=profile_rec.id AND

	stu_serv_rec.id=id_rec.id AND
	stu_serv_rec.yr=? AND
	stu_serv_rec.sess=? AND

	stu_acad_rec.id=id_rec.id AND
	stu_acad_rec.prog=? AND
	stu_acad_rec.sess=? AND
	stu_acad_rec.yr=? AND

	ed_rec.id=id_rec.id AND
	ed_rec.prim_sch= '1' AND
	
	sat.id=id_rec.id AND
	sat.ctgry='SAT' AND
	math.id=id_rec.id AND
	math.ctgry='S22C' AND

	reader_rec.id=id_rec.id AND

	ctc_rec.id=id_rec.id AND
	ctc_rec.resrc='CSPAWARD' AND
	ctc_rec.cgc='Y'

	INTO TEMP tmp_a WITH NO LOG

END

$debug=$sql;

#print STDERR "SQL=$sql\n";
##
## Build the final, data-retrieval query
##
my @selects = (
	"tmp_a.*"	,
	"tmp_sbcust_sp.enr_stat sbcust_sp_enr_stat",
	"tmp_sbcust_fa.enr_stat sbcust_fa_enr_stat",
	"tmp_stuserv_sp.intend_hsg sp_intend_hsg",
	"tmp_stuserv_fa.intend_hsg fa_intend_hsg",
	"tmp_sat.sat_verbal", 
	"tmp_sat.sat_math",
	"tmp_act.act_comp",
	"tmp_stustat.cum_gpa",
	"tmp_subb.pmt_terms",
	"tmp_aa.hs_st",
	"tmp_camp_ext.phone_ext"

);
my @froms = (
	"tmp_a",
	"outer tmp_sbcust_sp",
	"outer tmp_sbcust_fa",
	"outer tmp_stuserv_sp",
	"outer tmp_stuserv_fa",
	"outer tmp_sat",
	"outer tmp_act",
	"outer tmp_stustat",
	"outer tmp_subb",
	"outer tmp_aa",
	"outer tmp_camp_ext"
);

my @wheres = (

	"tmp_a.id=tmp_sbcust_sp.id" ,
	"tmp_a.id=tmp_sbcust_fa.id",
	"tmp_a.id=tmp_stuserv_sp.id",
	"tmp_a.id=tmp_stuserv_fa.id",
	"tmp_a.id=tmp_sat.id",
	"tmp_a.id=tmp_act.id",
	"tmp_a.id=tmp_stustat.id",
	"tmp_a.id=tmp_subb.subs_no",
	"tmp_a.id=tmp_aa.id",
	"tmp_a.id=tmp_camp_ext.id"
);
my @drops;


#open(F, '>/tmp/z.sql');
#print F $sql;
#close F;
#print STDERR "SQL=$sql\n";
	my $sth = $dbhelper->{dbh}->prepare($sql);
	! $sth && print STDERR DBI->errstr();
	$sth->execute(@vars,$prog,$prog, $yr, $sess, $prog, $sess, $yr);

my $sql = "select count(*) from tmp_a";
my $sth = $dbhelper->{dbh}->prepare($sql);
$sth->execute();
my ($count) = $sth->fetchrow_array();

#print STDERR "FOUND $count IN TMPA\n";

if ($id =~ /all/) {
		$buf .= "\nFound $count records ...";
		$cache->set($session, [0,$buf]);
}

	##
	## Get SP sbcust_rec info
	##
	my $sql = "select id, enr_stat FROM sbcust_rec WHERE ".
	          "id in (select id from tmp_a) AND prog=? and yr=? and sess IN ('SP')  INTO TEMP tmp_sbcust_sp WITH NO LOG";
	my $sth = $dbhelper->{dbh}->prepare($sql);
	my $rv = $sth->execute($prog,$yr);

	##
	## Get FA sbcust_rec info
	##
	my $sql = "select id, sess, enr_stat FROM sbcust_rec WHERE ".
	          "id in (select id from tmp_a) AND prog=? and yr=? and sess IN ('FA')  INTO TEMP tmp_sbcust_fa WITH NO LOG";
	my $sth = $dbhelper->{dbh}->prepare($sql);
	my $rv = $sth->execute($prog,$yr);

my $sql = "select count(*) from tmp_sbcust_sp";
my $sth = $dbhelper->{dbh}->prepare($sql);
$sth->execute();
my ($count) = $sth->fetchrow_array();

#return {};


	##
	## Get SP stu_serv_rec info
	##
	my $sql = "select id, intend_hsg FROM stu_serv_rec WHERE ".
	          "id IN (select id from tmp_a ) AND yr=? and sess IN ('SP') INTO TEMP tmp_stuserv_sp WITH NO LOG";
	my $sth = $dbhelper->{dbh}->prepare($sql);
	my $rv = $sth->execute($yr);
	warn DBI->errstr() if ! $rv;


	##
	## Get FA stu_serv_rec info
	##
	my $sql = "select id, sess, intend_hsg FROM stu_serv_rec WHERE ".
	          "id IN (select id from tmp_a ) AND yr=? and sess IN ('FA') INTO TEMP tmp_stuserv_fa WITH NO LOG";
	my $sth = $dbhelper->{dbh}->prepare($sql);
	my $rv = $sth->execute($yr);
	warn DBI->errstr() if ! $rv;


	##
	## Get campus phone extension
	##
	my $sql = "SELECT stu_serv_rec.id, facil_table.phone_ext ".
	          "FROM facil_table, stu_serv_rec ".
				 "WHERE stu_serv_rec.id IN (select id from tmp_a) AND ".
				 "stu_serv_rec.campus=facil_table.campus AND ".
				 "stu_serv_rec.bldg=facil_table.bldg AND ".
				 "stu_serv_rec.room=facil_table.room AND ".
				 "stu_serv_rec.yr=? AND stu_serv_rec.sess=? ".
				 "INTO TEMP tmp_camp_ext WITH NO LOG";
	my $sth = $dbhelper->{dbh}->prepare($sql);
	my $rv = $sth->execute($yr, $sess );



	##
	## Get SAT scores
	##
	my $sql = "select id, max(score1) sat_verbal, max(score2) sat_math from exam_rec where id in ( select id from tmp_a) and ctgry=\'SATI\' group by id INTO TEMP tmp_sat WITH NO LOG";
	my $sth = $dbhelper->{dbh}->prepare($sql);
	my $rv = $sth->execute();
	warn DBI->errstr() if ! $rv;




	##
	## Get ACT Composite score
	##
	my $sql = "select id, max(score5) act_comp from exam_rec where id in (select id from tmp_a) AND ctgry=\'ACT\' group by id INTO TEMP tmp_act WITH NO LOG";
	my $sth = $dbhelper->{dbh}->prepare($sql);
	my $rv = $sth->execute();
	warn DBI->errstr() if ! $rv;


	##
	## Get Cumulative GPA
	##
	my $sql = "select id, cum_gpa from stu_stat_rec where id in (select id from tmp_a) AND prog=\'$prog\' INTO TEMP tmp_stustat WITH NO LOG";
	my $sth = $dbhelper->{dbh}->prepare($sql);
	my $rv = $sth->execute();
	warn DBI->errstr() if ! $rv;




	##
	## Get subb_rec info
	##
	my $sql = "select subb_rec.subs_no, subb_rec.pmt_terms ".
			  "FROM subb_rec, pbill_rec WHERE ".

			
			  "subb_rec.subs_no IN (select id from tmp_a) AND ".
			  "subb_rec.prd=pbill_rec.bal_prd AND ".

			  "pbill_rec.subs=? AND ".
			  "pbill_rec.prog=? AND ".
			  "pbill_rec.sess=? AND ".
			  "pbill_rec.yr=?  ".
			  "INTO TEMP tmp_subb WITH NO LOG";

	my $sth = $dbhelper->{dbh}->prepare($sql);
	my $rv = $sth->execute('S/A', $prog, $sess, $yr);
	warn DBI->errstr() if ! $rv;


	##
	## Get high school state
	##
	my $sql = <<EOD;
select
	ed_rec.id, aa_rec.st hs_st
from
	ed_rec,
	sch_rec,
	aa_rec
where 
	ed_rec.prim_sch='1'
	and ed_rec.id IN (select id from tmp_a)
	and ed_rec.sch_id=sch_rec.id
	and sch_rec.id=aa_rec.id
	and aa_rec.aa='PERM' AND
	( aa_rec.end_date is null or aa_rec.end_date > today or aa_rec.end_date = '')
	AND (aa_rec.beg_date is null or aa_rec.beg_date < today)
	INTO TEMP tmp_aa WITH NO LOG
EOD

	my $sth = $dbhelper->{dbh}->prepare($sql);
	my $rv = $sth->execute();
	warn DBI->errstr() if ! $rv;


	##
	## Get reader_rec.total-score
	##
	if ( $show->{isCheckedtotal_score}) {
		my $sql = <<EOD;
	select
		reader_rec.id, reader_rec.total_score total_score
	from
		reader_rec
	where 
		reader_rec.id IN (select id from tmp_a) 
		and reader_rec.prog=?
		INTO TEMP tmp_reader WITH NO LOG
EOD

		my $sth = $dbhelper->{dbh}->prepare($sql);
		if (! $sth) {
			die DBI->errstr;
		};
		my $rv = $sth->execute('');
		warn DBI->errstr() if ! $rv;

		push @selects, "tmp_reader.total_score";
		push @froms, "outer tmp_reader";
		push @wheres, "tmp_a.id=tmp_reader.id";
		push @drops, "tmp_reader";

	}
	else {
		push @selects, "\'\'";
	};


	##
	## Get cofhe ethnicity
	##
	if ( $show->{isCheckedcofhe_eth}) {
		my $sql = <<EOD;
		  SELECT 
			  id_rec.id,
			  (NVL(pcethnic_rec.ethnic_code," ")) ethnic_code1 
		  FROM 
			  id_rec, 
			  pcethnic_rec, 
			  pcadm_ethnic_table
		  WHERE 
				  id_rec.id = pcethnic_rec.id 
				  and id_rec.id in (select id from tmp_a)
				  and pcethnic_rec.ethnic_code  = pcadm_ethnic_table.ethnic_code 
				  and pcadm_ethnic_table.cx_assoc_prior =
						  (select min(aet.cx_assoc_prior)
							from   pcadm_ethnic_table aet
							where  aet.ethnic_code in
										 (select pce.ethnic_code
										  from   pcethnic_rec pce
										  where  pce.id = id_rec.id)) 

		  INTO TEMP tmp_cofhe_eth with no log;
EOD

		my $sth = $dbhelper->{dbh}->prepare($sql);
		if (! $sth) {
			die DBI->errstr;
		};
		my $rv = $sth->execute();
		warn DBI->errstr() if ! $rv;

		push @selects, "tmp_cofhe_eth.ethnic_code1";
		push @froms, "outer tmp_cofhe_eth";
		push @wheres, "tmp_a.id=tmp_cofhe_eth.id";
		push @drops, "tmp_cofhe_eth";

	}
	else {
		push @selects, "\'\'";
	};

	##
	## Get cofhe 
	##
	if ( $show->{isCheckedcofhe}) {
		my $sql = <<EOD;
		SELECT pcadmloc_rec.id, pcadmloc_rec.cofhe
		FROM pcadmloc_rec
		WHERE pcadmloc_rec.id in (select id from tmp_a)
		INTO TEMP tmp_cofhe WITH NO LOG;
EOD

		my $sth = $dbhelper->{dbh}->prepare($sql);
		if (! $sth) {
			die DBI->errstr;
		};
		my $rv = $sth->execute();
		warn DBI->errstr() if ! $rv;

		push @selects, "tmp_cofhe.cofhe";
		push @froms, "outer tmp_cofhe";
		push @wheres, "tmp_a.id=tmp_cofhe.id";
		push @drops, "tmp_cofhe";

	}
	else {
		push @selects, "\'\'";
	};


	my $sql = "SELECT " . 
					join(" , ", @selects) .
				 " FROM " .
				 	join(" , ", @froms) .
				 " WHERE " .
				 	join (" AND ", @wheres);

=item	
	my $sql = <<END;
select
	tmp_a.*	,
	tmp_sbcust_sp.enr_stat sbcust_sp_enr_stat,
	tmp_sbcust_fa.enr_stat sbcust_fa_enr_stat,
	tmp_stuserv_sp.intend_hsg sp_intend_hsg,
	tmp_stuserv_fa.intend_hsg fa_intend_hsg,
	tmp_sat.sat_verbal, 
	tmp_sat.sat_math,
	tmp_act.act_comp,
	tmp_stustat.cum_gpa,
	tmp_subb.pmt_terms,
	tmp_aa.hs_st,
	tmp_camp_ext.phone_ext
from
	tmp_a,
	outer tmp_sbcust_sp,
	outer tmp_sbcust_fa,
	outer tmp_stuserv_sp,
	outer tmp_stuserv_fa,
	outer tmp_sat,
	outer tmp_act,
	outer tmp_stustat,
	outer tmp_subb,
	outer tmp_aa,
	outer tmp_camp_ext
where
	tmp_a.id=tmp_sbcust_sp.id AND
	tmp_a.id=tmp_sbcust_fa.id AND
	tmp_a.id=tmp_stuserv_sp.id AND
	tmp_a.id=tmp_stuserv_fa.id AND
	tmp_a.id=tmp_sat.id AND
	tmp_a.id=tmp_act.id AND
	tmp_a.id=tmp_stustat.id AND
	tmp_a.id=tmp_subb.subs_no AND
	tmp_a.id=tmp_aa.id AND
	tmp_a.id=tmp_camp_ext.id

END
=cut
if ($id =~ /all/) {
		$buf .= "\nProcessing results ...";
		$cache->set($session, [0,$buf]);
}
	my $sth = $dbhelper->{dbh}->prepare($sql);
#print STDERR DBI->errstr();
my $count=1;
	$sth->execute();
my $seen = {};
	my @results;

	while ( my ($ss_no,$id,$fullname,

               $perm_line1,$perm_line2,$perm_city,$perm_ctry,$perm_zip,	
					$perm_phone,$perm_st,

					$camp_line1, $camp_line2,

					$eml1,

					$plan_grad_yr, $plan_grad_sess, $adm_stat, $enr_date,
					$prog, $major1, $lv_date, $adm_yr, $adm_sess,

					$cur_enr_date, $fa, $decsn, $early_decsn, $trnsfr, $enrstat,
					$plan_enr_yr, $first_gen, $plan_enr_sess, $stutype,

					$ethnic_code1, $ethnic_code2, $ethnic_code3, $ethnic_code4,

					$citz, $sex, $ethnic_code, $birth_date,

					$res_asst,

					$reg_hrs, $cl,
					
					$hs_gpa, $hs_rank, $hs_size, $percentile,
	
					$score1, $score2, $score3, $score5,

					$decsn_rank, $non_tally, $resrc,

					## NOW THE TMP TABLES
					$sbcust_sp_enr_stat, $sbcust_fa_enr_stat,


					$sp_intend_hsg, $fa_intend_hsg,

					$sat_verbal, $sat_math,

					$act_comp,

					$cum_gpa,

					$pmt_terms,

					$hs_st,

					$camp_phone_ext,

					$total_score,

					$cofhe_eth,

					$cofhe

	) = $sth->fetchrow_array() ) {
#if ( $seen->{"$id"} > 0) {
#	print STDERR "ID=$id ($count)\n" ;
#	$count++;
#};
	$seen->{$id}++;
	my $master = {};

#print STDERR "id=$id -- camp phone=$camp_phone_ext \n";
#print STDERR "count=$count\n";$count++;
#print STDERR "eml1=$eml1\n";

	## tmp tables
	$master->{"sp_enr_stat"} = $sbcust_sp_enr_stat;
	$master->{"fa_enr_stat"} = $sbcust_fa_enr_stat;
	$master->{"sp_intend_hsg"} = $sp_intend_hsg;
	$master->{"fa_intend_hsg"} = $fa_intend_hsg;
	$master->{'sat_verbal'} = $sat_verbal;
	$master->{'sat_math'} = $sat_math;
	$master->{'act_comp'} = $act_comp;

	$cum_gpa = sprintf ( '%.0f', $cum_gpa * 100);
	$master->{'cum_gpa'} = $cum_gpa;

	$pmt_terms = 'D' if $pmt_terms =~ 'DEFR';
	$pmt_terms = 'F' if $pmt_terms =~ 'FPAY';
	$master->{"pmt_terms"} = $pmt_terms;
	$master->{"hs_st"} = $hs_st;
	$master->{camp_phone_ext} = $camp_phone_ext;
	$master->{total_score} = $total_score;
	$master->{cofhe_eth} = $cofhe_eth;
	$master->{cofhe} = $cofhe;





		## no dashes
		$ss_no =~ s/-//g;

		## 04/20/04 -- if ss_no empty, fill it w/ carsid+0
		## 1/13/04, make emtpy ssn 8 + carsid ticket 104
		if ($ss_no =~ /^\s*$/) {
			$ss_no = '8' . $id;
		};

		## nothing but nums
		$perm_phone =~ s/[^0-9]//g;

		## no slashes
		foreach ( $enr_date, $lv_date, $birth_date, $cur_enr_date ) {
			s/\///g;
		};



		## map the prog
		if ( $prog eq 'UNDG') {
			$prog = '01';
		}
		else {
			$prog='02';
		};


		## map the adm citizenship
		my $adm_citz = $citz;
		if ( $adm_citz eq 'USA' || $adm_citz eq '') {
			$adm_citz = 'U';
		}
		else {
			$adm_citz = 'F';

		};


		## map the ODEC and ADMSTAT
		my ($odec,$admstat);
		if ($enrstat =~ /^(?:E1|E2|R)$/) {
			$odec = $enrstat;	
		}
		elsif ( $enrstat eq 'APPLY') {
			$admstat = 'L';
		}
		elsif ( $enrstat eq 'DEFER') {
			$admstat = 'E';
		}
		elsif ( $enrstat =~ /^INQUIR/) {
			$admstat = 'Q';
		}
		elsif ( $enrstat eq 'READ') {
			$admstat = 'M';
		}
		elsif ( $enrstat eq 'RESCIND') {
			$admstat = 'O';
		}
		elsif ( $enrstat eq 'WA') {
			$admstat = 'P';
		}
		elsif ( $enrstat eq 'WB') {
			$admstat = 'T';
		}
		elsif ( $enrstat eq 'WD') {
			$admstat = 'U';
		}
		elsif ( $enrstat eq 'WL') {
			$admstat = 'V';
		}
		elsif ( $enrstat eq 'WLRELEAS') {
			$admstat = 'W';
		}
		elsif ( $enrstat eq 'WLSTAY') {
			$admstat = 'X';
		}
		elsif ( $enrstat eq 'WLWD') {
			$admstat = 'Y';
		}
		elsif ( $enrstat eq 'WP') {
			$admstat = 'Z';
		}
		elsif ( $enrstat eq 'MS') {
			$admstat = 'S';
		}

		$master->{ss_no} = $ss_no;
		$master->{id} = $id;
		$master->{fullname} = $fullname;

		## parse the fullname, store the fname etc in the $id_rec hashref
		my ($fname, $lname, $fname_sndx, $lname_sndx, $full_sndx, $fi, $li, $mi) = &DupCheck::name2sndx($fullname);
		$master->{fname} = $fname;
		## lname no longer than 16
		$lname = substr($lname,0,16) if length($lname) > 16;
		$master->{lname} = $lname;
		$master->{mi} = $mi;


		$master->{perm_line1} = $perm_line1;
		$master->{perm_line2} = $perm_line2;
		$master->{perm_city} = $perm_city;
		$master->{perm_ctry} = $perm_ctry;
		$master->{perm_zip} = $perm_zip;
		$master->{perm_phone} = $perm_phone;
		$master->{perm_st} = $perm_st;
		$master->{camp_line1} = $camp_line1;
		$master->{camp_line2} = $camp_line2;
		$master->{eml1} = $eml1;
		$master->{plan_grad_yr} = $plan_grad_yr;
		$master->{plan_grad_sess} = $plan_grad_sess;
#		$master->{adm_stat} = $adm_stat;
		$master->{adm_stat} = $admstat;
		$master->{enr_date} = $enr_date;
		$master->{prog} = $prog;
		$master->{major1} = $major1;
		$master->{lv_date} = $lv_date;

		$master->{adm_yr} = "$adm_yr" if $adm_yr;
		$master->{adm_sess} = "$adm_sess" if $adm_sess;

#		$cur_enr_date =~ s|\d\d(\d\d)$|$1|; # shorten year to 2 chars

		$master->{cur_enr_date} = $cur_enr_date;
		$master->{odec} = $odec;

		$master->{fa} = $fa;
		$master->{decsn} = $decsn;
		$master->{early_decsn} = $early_decsn;
		$master->{trnsfr} = $trnsfr;
		$master->{plan_enr_yr} = $plan_enr_yr;
		$master->{first_gen} = $first_gen;
		
		if ($plan_enr_sess eq 'FA'){
			$master->{plan_enr_sess} = 'FALL';
		}elsif($plan_enr_sess eq 'SP'){	
			$master->{plan_enr_sess} = 'SPRI';
		}elsif($plan_enr_sess eq 'SU'){	
			$master->{plan_enr_sess} = 'SUMM';
		}else{
			$master->{plan_enr_sess} = '';
		}

		$master->{stutype} = stutype;

		$master->{ethnic_code1} = $ethnic_code1;
		$master->{ethnic_code2} = $ethnic_code2;
		$master->{ethnic_code3} = $ethnic_code3;
		$master->{ethnic_code4} = $ethnic_code4;

		$master->{citz} = $citz;
		$master->{adm_citz} = $adm_citz;
		$master->{sex} = $sex;
		$master->{ethnic_code} = $ethnic_code;
#		$birth_date =~ s|\d\d(\d\d)$|$1|; # shorten year to 2 chars
		$master->{birth_date} = $birth_date;
		
		$master->{res_asst} = $res_asst;

		$reg_hrs = sprintf ( '%.0f', $reg_hrs * 100);
#		$master->{reg_hrs} = $reg_hrs == 0 ? 0 : $reg_hrs;
		$master->{reg_hrs} = $reg_hrs ;
		$master->{hs_gpa} = $hs_gpa;
		$master->{hs_rank} = $hs_rank;
		$master->{hs_size} = $hs_size;
		$master->{cl}      = $cl;
		$master->{percentile} = $percentile;
		
		$master->{score1} = $score1;
		$master->{score2} = $score2;
		$master->{score3} = $score3;
		$master->{score5} = $score5;

		$master->{decsn_rank} = substr($decsn_rank,0,1);
		$master->{non_tally} = $non_tally;

		$master->{resrc} = substr($resrc,0,4);
		
		## construct the expected graduation date
		if ($plan_grad_sess && $plan_grad_yr && ($plan_grad_sess =~ /SP|FA/) ) {

			## SP becomes 05
			if ($plan_grad_sess eq 'SP' ) {
				$exp_grad_date="0517$plan_grad_yr";
			}

			## FA becomes 12
			if ($plan_grad_sess eq 'FA' ) {
				$exp_grad_date="1219$plan_grad_yr";
			};
			$master->{exp_grad_date} = $exp_grad_date;
		};


		##
		## Get athletic code
		##
		$master->{athletic} = 'XX';

		push @results, $master;

#		open(F, ">/tmp/apachelog");
#		print F Dumper $master;
#		close(F);

	};
#print STDERR "REPEATED $count\n";
	foreach my $tmp (qw(tmp_a tmp_sbcust_sp tmp_sbcust_fa tmp_stuserv_sp
	                    tmp_stuserv_fa tmp_sat tmp_act tmp_stustat tmp_subb tmp_aa tmp_camp_ext),  @drops) {
		$sql = "drop table $tmp";
		my $sth = $dbhelper->{dbh}->prepare($sql);
		$sth->execute();
	};

	return [@results];

};


sub make_col_headers {
	my @headers = (

				"ss_no",
            "id",
            "lname",
            "fname",
            "mi",
            "perm_line1",
            "perm_line2",
            "perm_city",
            "perm_st",
            "perm_ctry",
            "perm_zip",
            "perm_zip4",
            "perm_phone",
				'C?',
				"",
            "camp_line1",
            "camp_line2",
				"",
				"",
				"",
				"",
				"",
				"camp_phone_ext",
				"eml1",
				"",
				"",
				"",
				"",
				"",
				"adm_stat",
				"",
				"",
				"",
				"",
				"hs_gpa",
				" ",
				"sat_verbal",
				"sat_math",
				"act_comp" ,
				" ",
				" ",
				" ",
				" ",
				"prog" ,
				"major1" ,
				"trnsfr" ,
				" ",
				"lv_date" ,
				"exp_grad_date",
				"enr_date",
				" ",
				"fid plan_grad_yr",
				"plan_grad_yr",
				"fid adm_yr",
				"adm_yr",
				"fid cum_gpa",
				"cum_gpa",
				"fid cur_enr_date",
				"cur_enr_date",
				"fid percentile",
				"percentile",
				"fid reg_hrs",
				"reg_hrs",
				"fid hs_rank",
				"hs_rank",
				"fid hs_size",
				"hs_size",
				"fid birth_date",
				"birth_date",
				"fid plan_enr_yr",
				"plan_enr_yr",
				"fid score1",
				"score1",
				"fid score2",
				"score2",
				"fid score3",
				"score3",
				"fid score5",
				"score5",
				"fid decsn_rank",
				"decsn_rank",
				"fid pmt_terms",
				"pmt_terms",
				"fid sex",
				"sex",
				"fid nm_applicant",
				"nm_applicant",
				"fid adm_prog",
				"adm_prog",
				"fid res_asst",
				"res_asst",
				" ",
				" ",
				"fid plan_enr_sess",	
				"plan_enr_sess",
				"fid non_tally",
				"non_tally",
				"fid resrc",
				"resrc",
				"fid adm_citz",
				"adm_citz",
				"fid ethnic_code1",
				"ethnic_code1",
				"fid ethnic_code2",
				"ethnic_code2",
				"fid ethnic_code3",
				"ethnic_code3",
				"fid ethnic_code4",
				"ethnic_code4",
				"fid fa",
				"fa",
				"fid decsn",
				"decsn",
				"fid early_decsn",
				"early_decsn",
				"fid fa_enr_stat",
				"fa_enr_stat",
				"fid fa_intend_hsg",
				"fa_intend_hsg",
				"fid hs_st",
				"hs_st",
				"fid odec",
				"odec",
				"fid total_score",
				"total_score",
				"fid sp_enr_stat",
				"sp_enr_stat",
				"fid sp_intend_hsg",
				"sp_intend_hsg",
				"fid class standing",
				"class standing",
				"fid adm_sess",
				"adm_sess"       ,
				"fid ethnic code",
				"ethnic_code"    ,
				"fid_first_gen",
				"first_gen",
				"fid_cofhe",
				"cofhe",
				"fid_cofhe_eth",
				"cofhe_eth",
				"stutype",
				"fid stutype",
				" ",
				" ",
				"citz",
				" " ,
				" " ,
				"athletic",
				" "
						);
	return [@headers];
};

1;

