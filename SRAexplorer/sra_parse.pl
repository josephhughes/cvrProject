use Bio::DB::EUtilities;
use Bio::Tools::EUtilities;
use Bio::Tools::EUtilities::Summary::Item;

#searches the SRA database for every entry
my $factory = Bio::DB::EUtilities->new(-eutil => 'esearch',
                                       -db     => 'sra',
                                       -term   => 'public OR controlled',
                                       -email  => '2023085m@student.gla.ac.uk',
					-usehistory => 'y');

# query terms are mapped; what's the actual query?
#print "Query translation: ",$factory->get_query_translation,"\n";

# query hits
#print "Count = ",$factory->get_count,"\n";

#Creates a variable equal to the no. of query hits
my $count = $factory->get_count;

#get history from queue
my $hist = $factory->next_History || die 'No history data returned';

#the new iterative query based upon history
my $factory = Bio::DB::EUtilities->new(-eutil => 'esummary',
                                       -email => '2023085m@student.gla.ac.uk',
                                       -db    => 'sra',
					-history => $hist);


#the header for the text document, tab seperated.
print "ID\tStudyAcc\tSubmitterAcc\tTaxID\tOrganism\tDate\tUpdateDate\tCompany\tModel\tBases\tDescription\tDesign\tCenter\tContactName\tLaboratory\tLibraryName\tLibraryStrategy\tLibrarySource\tLibrarySelection\tbioProj\tbioSample\n";

#the code will iterate when the retstart is less that the total hit count.
my $retry = 0; my ($retmax, $retstart) = (10000,0);
while ($retstart < $count) {
    $factory->set_parameters(-retmax => $retmax,
                             -retstart => $retstart);
    eval{
        $factory->get_Response(-cb =>
            sub {my ($data) = @_; print $out $data} );
    };

#if the server is unresponsive, it retries 5 times before stopping 'dying'
    if ($@) {
        die "Server error: $@.  Try again later" if $retry == 5;
        print STDERR "Server error, redo #$retry\n";
        $retry++;
    }
#	print "Retrieved $retstart";
    $retstart += $retmax;


close $out;

#if the query has results the following will happen
while (my $ds = $factory->next_DocSum){

  #variables
my ($taxId,$id,$name,$design,$platform,$model,$bases,$date,$des,$study);
  $id=$ds->get_id;

  
while (my $item = $ds->next_Item) {
     $name=$item->get_name;
     my $data=$item->get_content;

#code to parse out design, model, platform and bases.
if($data=~/\<Summary><Title\>(.+)\<\/Title\>\<Platform instrument_model\=\"(.+)\"\>(.+)\<\/Platform\>\<Statistics total_runs\=\"(.+)\" total_spots\=\"(.+)\" total_bases\=\"(.+)\" total_size/){     
	  $design=$1;
	  $design=~s/\t//g;
          $model=$2;
          $platform=$3;
	  $platform=~s/\t//g;
	  $bases=$6;
}
#parsing out create date and update date      
if ($name="CreateDate"){
	$date=$item->get_content;
	$date1=$item->get_content;
}
#parsing out submission acession, center name, contact name, and lab name.
if($data=~/\<Submitter acc\=\"(.+)\" center_name\=\"(.+)\" contact_name\=\"(.+)\" lab_name\=\"(.+)\"\/><Experiment/)
{
 $submitter=$1;
 $submitter=~s/\t//g;
 $center=$2;
 $center=~s/\t//g;
 $contact=$3;
 $contact=~s/\t//g;
 $lab=$4;
 $lab=~s/\t//g;
}
#parsing out the study accession number, description, taxonomic ID and organism (common name)
if($data=~/\<Study acc\=\"(.+)\" name\=\"(.+)\"\/\>\<Organism taxid\=\"(.+)\" CommonName\=\"(.+)\"\/\>\<Sample/){
	$study=$1;
	$study=~s/\t//g;
	$des=$2;
	$des=~s/\t//g;
	$taxId=$3;
	$taxId=~s/\t//g;
	$organ=$4;
	$organ=~s/\t//g;		


}	
#parsing out library name, library strategy, library source and library selection
if ($data=~/\<LIBRARY_NAME\>(.+)\<\/LIBRARY_NAME>\<LIBRARY_STRATEGY\>(.+)\<\/LIBRARY_STRATEGY>\<LIBRARY_SOURCE\>(.+)\<\/LIBRARY_SOURCE>\<LIBRARY_SELECTION\>(.+)\<\/LIBRARY_SELECTION>\<LIBRARY_LAYOUT/)
{
$libName=$1;
$libStrat=$2;
$libSource=$3;
$libSelect=$4;

}
#finally, parsing out the Bioproject and Biosample ID
if($data=~/\<Bioproject\>(.+)\<\/Bioproject\>\<Biosample\>(.+)\<\/Biosample>/)
{
$bioProj=$1;
$bioSample=$2;
}
}




 
#printing variables for each submission in the SRA.
print "$id\t$study\t$submitter\t$taxId\t$organ\t$date\t$date1\t$platform\t$model\t$bases\t$des\t$design\t$center\t$contact\t$lab\t$libName\t$libStrat\t$libSource\t$libSelect\t$bioProj\t$bioSample\n";


}
}
