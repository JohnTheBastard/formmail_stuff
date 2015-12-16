#!/usr/bin/env perl

#use strict;

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

##
## The order of output
##
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
   push @vars, 'C';                               $fmt.=field(1);   # seconday addr destination
   push @vars, undef;                             $fmt.=field(8);   # secondary date of expiration
   push @vars, $masked_ref->{camp_line1};         $fmt.=field(30);
   push @vars, $masked_ref->{camp_line2};         $fmt.=field(30);
   push @vars, undef;                             $fmt.=field(17);  # campus city
   push @vars, undef;                             $fmt.=field(2);   # campus st
   push @vars, undef;                             $fmt.=field(15);  # campus country
   push @vars, undef;                             $fmt.=field(5);   # campus zip
   push @vars, undef;                             $fmt.=field(4);   # campus zip+4
   push @vars, $masked_ref->{camp_phone_ext};     $fmt.=field(10);
   push @vars, $masked_ref->{eml1};               $fmt.=field(40);
   push @vars, undef;                             $fmt.=field(8);   # birth date
   push @vars, undef;                             $fmt.=field(2);   # state of legal residence
   push @vars, undef;                             $fmt.=field(1);   # residency
   push @vars, undef;                             $fmt.=field(1);   # housing
   push @vars, undef;                             $fmt.=field(6);   # formerly $masked_ref->{exp_grad_date}
   push @vars, $masked_ref->{adm_stat};           $fmt.=field(1);
   push @vars, undef;                             $fmt.=field(1);   # citizenship
   push @vars, undef;                             $fmt.=field(1);   # 2nd back degree
   push @vars, undef;                             $fmt.=field(1);   # title/gender
   push @vars, undef;                             $fmt.=field(1);   # vet status
   push @vars, $masked_ref->{hs_gpa};             $fmt.=field(3);
   push @vars, undef;                             $fmt.=field(3);   # college gpa
   push @vars, $masked_ref->{sat_verbal};         $fmt.=field(2);
   push @vars, $masked_ref->{sat_math};           $fmt.=field(2);
   push @vars, $masked_ref->{act_comp};           $fmt.=field(2);
   push @vars, undef;                             $fmt.=field(1);   # satisfactory progress
   push @vars, undef;                             $fmt.=field(6);   # enrollment date
   push @vars, undef;                             $fmt.=field(4);   # credits/hours
   push @vars, undef;                             $fmt.=field(2);   # version
   push @vars, $masked_ref->{prog};               $fmt.=field(2);
   push @vars, $masked_ref->{major1};             $fmt.=field(4);
   push @vars, $masked_ref->{trnsfr};             $fmt.=field(1);
   push @vars, undef;                             $fmt.=field(3);   # counselor
   push @vars, $masked_ref->{lv_date};            $fmt.=field(8);
   push @vars, $masked_ref->{exp_grad_date};      $fmt.=field(8);
   push @vars, $masked_ref->{enr_date};           $fmt.=field(8);
   push @vars, undef;                             $fmt.=field(310); # from col 405-714
   push @vars, $masked_field_ids->{plan_grad_yr}; $fmt.=field(6);
   push @vars, $masked_ref->{plan_grad_yr};       $fmt.=field(8);
   push @vars, $masked_field_ids->{adm_yr};       $fmt.=field(6);
   push @vars, $masked_ref->{adm_yr};             $fmt.=field(8);
   push @vars, $masked_field_ids->{cum_gpa};      $fmt.=field(6);
   push @vars, $masked_ref->{cum_gpa};            $fmt.=field(8);
   push @vars, $masked_field_ids->{cur_enr_date}; $fmt.=field(6);
   push @vars, $masked_ref->{cur_enr_date};       $fmt.=field(8);
   # push @vars, undef;                           $fmt.=field(0);   # sdec field ID - HMC removed
   # push @vars, undef;                           $fmt.=field(0);   # sdec - HMC removed
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
   # push @vars, undef;                           $fmt.=field(0);   # cols 855-1274 - HMC removed
   push @vars, $masked_field_ids->{score1};       $fmt.=field(6);   # HMC add
   push @vars, $masked_ref->{score1};             $fmt.=field(8);   # HMC add
   push @vars, $masked_field_ids->{score2};       $fmt.=field(6);   # HMC add
   push @vars, $masked_ref->{score2};             $fmt.=field(8);   # HMC add
   push @vars, $masked_field_ids->{score3};       $fmt.=field(6);   # HMC add
   push @vars, $masked_ref->{score3};             $fmt.=field(8);   # HMC add
   push @vars, $masked_field_ids->{score5};       $fmt.=field(6);   # HMC add
   push @vars, $masked_ref->{score5};             $fmt.=field(8);   # HMC add
   push @vars, $masked_field_ids->{decsn_rank};   $fmt.=field(6);   # HMC add
   push @vars, $masked_ref->{decsn_rank};         $fmt.=field(358); # HMC add
   # push @vars, undef;                           $fmt.=field(350);   # cols 939-1274 - HMC comment Date/Int ends
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
   push @vars, $masked_field_ids->{non_tally};    $fmt.=field(91);  # HMC add
   push @vars, $masked_ref->{non_tally};          $fmt.=field(6);   # HMC add
   push @vars, $masked_field_ids->{resrc};        $fmt.=field(5);   # HMC add
   push @vars, $masked_ref->{resrc};              $fmt.=field(6);   # HMC add
   push @vars, $masked_field_ids->{adm_citz};     $fmt.=field(5);
   push @vars, $masked_ref->{adm_citz};           $fmt.=field(6);
   push @vars, $masked_field_ids->{ethnic_code1}; $fmt.=field(5);
   push @vars, $masked_ref->{ethnic_code1};       $fmt.=field(6);
   push @vars, $masked_field_ids->{ethnic_code2}; $fmt.=field(5);
   push @vars, $masked_ref->{ethnic_code2};       $fmt.=field(6);
   push @vars, $masked_field_ids->{ethnic_code3}; $fmt.=field(5);
   push @vars, $masked_ref->{ethnic_code3};       $fmt.=field(6);
   push @vars, $masked_field_ids->{ethnic_code4}; $fmt.=field(5);
   push @vars, $masked_ref->{ethnic_code4};       $fmt.=field(6);
   push @vars, $masked_field_ids->{fa};           $fmt.=field(5);
   push @vars, $masked_ref->{fa};                 $fmt.=field(6);
   push @vars, $masked_field_ids->{early_decsn};  $fmt.=field(5);
   push @vars, $masked_ref->{early_decsn};        $fmt.=field(6);
   push @vars, $masked_field_ids->{fa_enr_stat};  $fmt.=field(5);
   push @vars, $masked_ref->{fa_enr_stat};        $fmt.=field(6);
   push @vars, $masked_field_ids->{fa_intend_hsg};$fmt.=field(5);
   push @vars, $masked_ref->{fa_intend_hsg};      $fmt.=field(6);
   push @vars, $masked_field_ids->{hs_st};        $fmt.=field(5);
   push @vars, $masked_ref->{hs_st};              $fmt.=field(6);
   push @vars, $masked_field_ids->{odec};         $fmt.=field(5);
   push @vars, $masked_ref->{odec};               $fmt.=field(6);
   push @vars, $masked_field_ids->{total_score};  $fmt.=field(5);
   push @vars, $masked_ref->{total_score};        $fmt.=field(6);
   push @vars, $masked_field_ids->{sp_enr_stat};  $fmt.=field(5);
   push @vars, $masked_ref->{sp_enr_stat};        $fmt.=field(6);
   push @vars, $masked_field_ids->{sp_intend_hsg};$fmt.=field(5);
   push @vars, $masked_ref->{sp_intend_hsg};      $fmt.=field(6);
   push @vars, $masked_field_ids->{cl};           $fmt.=field(5);
   push @vars, $masked_ref->{cl};                 $fmt.=field(6);
   push @vars, $masked_field_ids->{adm_sess};     $fmt.=field(5);
   push @vars, $masked_ref->{adm_sess};           $fmt.=field(6);
   push @vars, $masked_field_ids->{ethnic_code};  $fmt.=field(5);
   push @vars, $masked_ref->{ethnic_code};        $fmt.=field(6);
   push @vars, $masked_field_ids->{first_gen};    $fmt.=field(5);
   push @vars, $masked_ref->{first_gen};          $fmt.=field(6);
   push @vars, $masked_field_ids->{cofhe};        $fmt.=field(5);
   push @vars, $masked_ref->{cofhe};              $fmt.=field(6);
   push @vars, $masked_field_ids->{cofhe_eth};    $fmt.=field(50);
   push @vars, $masked_ref->{cofhe_eth};          $fmt.=field(6);
   # push @vars, undef;                           $fmt.=field(0);   # HMC removed
   # push @vars, undef;                           $fmt.=field(0);   # HMC removed
   push @vars, undef;                             $fmt.=field(50);  # ???
   push @vars, undef;                             $fmt.=field(15);  # ???
   push @vars, $masked_ref->{citz};               $fmt.=field(1);
   push @vars, " ";                               $fmt.=field(98);  # ??? this is suspect
   push @vars, " ";                               $fmt.=field(2);   # ??? this is suspect
   push @vars, $masked_ref->{athletic};           $fmt.=field(138);
   push @vars, undef;                             $fmt.=field(0);   # ???
   
print \n$fmt\n";
exit 0;

