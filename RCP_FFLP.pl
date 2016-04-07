#!/usr/bin/perl
use strict;
use warnings;
use FindBin qw($Bin);
use IO::Handle;
use Text::CSV_XS;
use feature qw(say);
use Tkx;
my $config = {
    #file    => "$Bin/local7.20150511",
    #headers => [qw(MONTH DAY TIME IP)],
};
my $mw = Tkx::widget->new('.');
$mw->g_wm_title("Log Parser v1.0");
$mw->g_wm_minsize( 500, 100 );
my $btn_start = $mw->new_ttk__button(
    -text    => "Start",
    -width   => 80,
    -command => sub { start(); },
);
my $btn_exit = $mw->new_ttk__button(
    -text    => "Exit",
    -width   => 80,
    -command => sub { exit(); },
);
my $lbl_source_file = $mw->new_tk__label( -text => "Log File:" );
my $txt_source_file =
  $mw->new_tk__entry( -textvariable => \$config->{file}, -width => 55 );
my $btn_source_file = $mw->new_tk__button(
    -text    => "LOAD FILE",
    -command => sub { get_source_filename(); }
);
Tkx::grid(
    $lbl_source_file,
    -row    => 0,
    -column => 0,
    -padx   => 10,
    -pady   => 10,
    -sticky => "w"
);
Tkx::grid(
    $btn_source_file,
    -row    => 0,
    -column => 2,
    -padx   => 10,
    -pady   => 1,
    -sticky => "e"
);
Tkx::grid( $txt_source_file, -row => 0, -column => 1, -padx => 1, -pady => 1 );
Tkx::grid( $btn_start, -row => 3, -columnspan => 3, -padx => 10, -pady => 1 );
Tkx::grid( $btn_exit,  -row => 4, -columnspan => 3, -padx => 10, -pady => 1 );
Tkx::MainLoop();
sub start {
    $config->{csv} = Text::CSV_XS->new()
      or die "Cannot use CSV: " . Text::CSV_XS->error_diag();
    open( $config->{fh}, ">", "$Bin/RCP_FFLP.csv" )
      or die "Failed to create file [$Bin/RCP_FFLP.csv]: $!";
    $config->{fh}->autoflush(1);
    parse_log( $config->{file}, 0, $config );
    $config->{csv}->combine( @{ $config->{headers} } );
    print { $config->{fh} } $config->{csv}->string(), "\n";
    parse_log( $config->{file}, 1, $config );
    close $config->{fh} or die "RCP_FFLP.csv: $!";
    #say "COMPLETED";
    Tkx::tk___messageBox( -message => "COMPLETED" );
}
sub parse_log {
    my $file   = shift;
    my $action = shift;
    my $config = shift;
    if ( -e $file ) {
        open( my $fh, "<", $file ) or die $!;
        while ( my $line = readline($fh) ) {
            $line =~ s/[\r\n]//g;
            my $record;
            ( $record->{start_token} ) = $line =~ m/^([^=]+) \s+ \S+=/x;
            $line =~ s/^[^=]+ \s+ (\S+)=/$1=/x;
            my @start_line_values = split /\s+/, $record->{start_token};
            while ( my ( $index, $value ) = each @start_line_values ) {
                unless ( $config->{headers_index}->{ "Column_" . ( $index + 1 ) } )
                {
                    $config->{headers_index}->{ "Column_" . ( $index + 1 ) } = 1;
                    push @{ $config->{headers} }, "Column_" . ( $index + 1 );
                }
                if ($action) {
                    $record->{ "Column_" . ( $index + 1 ) } = $value;
                }
            }
            while ( $line =~ m{(\S+)=( [^\s"]+ | "[^"]*" )}xg ) {
                my ( $field, $value ) = ( $1, $2 );
                $value =~ s/^"|"$//g;
                unless ( $config->{headers_index}->{$field} ) {
                    $config->{headers_index}->{$field} = 1;
                    push @{ $config->{headers} }, $field;
                }
                if ($action) {
                    $record->{$field} = $value;
                }
            }
            if ($action) {
                save_record( $record, $config );
            }
        }
        close $fh;
    }
}
sub save_record {
    my $record = shift;
    my $config = shift;
    $config->{csv}->combine( @{$record}{ @{ $config->{headers} } } );
    print { $config->{fh} } $config->{csv}->string(), "\n";
}
sub get_source_filename {
    $config->{file} = Tkx::tk___getOpenFile();
}
