use v6;
use Gumbo::Binding;
use NativeCall::TypeDiag;
my @headers = <gumbo.h>;
my @libs = <-lgumbo>;


my %typ = (GumboElement => ::("gumbo_element_s"), GumboDocument => ::("gumbo_document_s"), 
"GumboText" => ::("gumbo_text_s"), GumboOutput =>  ::("gumbo_output_s"), GumboNode =>  ::("gumbo_node_s"));


diag-cstructs(:cheaders(@headers), :types(%typ), :clibs(@libs));

my $t = ::("gumbo_node_s");
diag-struct("GumboNode", $t, :cheaders(@headers), :clibs(@libs));

