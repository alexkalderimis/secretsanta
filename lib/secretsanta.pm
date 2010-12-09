package secretsanta;
use Dancer ':syntax';
use Digest::MD5 ("md5");
use autodie;

use 5.10.0;

our $VERSION = '0.1';

my $csv = Text::CSV->new({binary => 1});

get '/secretsanta' => sub {
    template 'index';
};

get '/secretsanta/join' => sub {
    my $email_address = params->{email_address};
    my $name = params->{name};
    my $location = params->{location};
    my $digest = md5($email_address . 'sysbiol_secret_santa');
    my $email_already_exists = email_in_csv($email);
    $csv->combine($email_address, $name, $location, $digest);
    my $csv_line = $csv->string;
    my $message;
    if ($email_already_exists and $authenticated) {
        $message = "Thank you for supplying these new details. Please check your email and click the link to confirm them";
        add_to_unauthenticateds($csv_line);
    } elsif($email_already_exists) {
        $message = "We haven't received your authentication yet. Please check your email and click on the link";
    } else {
        $message = "Thank you for offering to be a secret santa! Please check your email and click on the link to confirm these details";
        add_to_unauthenticateds($csv_line);
    }
    return $message;
}

get '/secretsanta/authenticate/:digest' => sub {
    open my $io_in, '<', $unauthenticated_file;
    rename $unauthenticated_file, $unauthenticated_file . $back_up_ext;
    open my $io_out, '>', $unauthenticated_file;
    while ( my $row = $csv->getline($io_in) ) {
        if ($row->[3] eq params->{digest}) {
            my ($email, $name, $location, $digest) = @$row;
            open my $auth_io, '>>', $authenticated_file;
            $csv->combine($email, $name, $location);
            say $auth_io $csv->string;
            close $auth_io;
        } else {
            $csv->print($io_out, $row);
        }
    }
    close $io_in;
    close $io_out;
}

sub add_to_unauthenticateds {
    my $csv_line = shift;
    open my $fh, '>>', $unauthenticated_file;
    say $fh $csv_line;
    close $fh;
}

true;
