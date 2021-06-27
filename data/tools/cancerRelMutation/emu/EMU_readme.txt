README.txt
^^^^^^^^^^^^^^^
^^^^^^^^^^^^^^^

A/
Pipeline of Extaction of MUtation:
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
1. input of EMU is a text file, each line consist of a tabdelimited triplet of 1) pubmed id, 2) title and 3) the plain text of the abstract.
2. Use EMU on the input file.
3. use the SEQ_filter on the mutations extracted.

detailed description:
^^^^^^^^^^^^^^^^^^^^^
A2 EMU:
^^^^^^^^^^^
EMU needs the following files:

hard coded filenames:
AAconversion.pm    %some perl scripts from Trevor.
HUGOGeneNames.txt  %the list of gene names.
Cell_line_list_short.txt   %the list of cell line names that can be confused with mutations i.e. cell line names that seems to be mutations.

syntax:
perl EMUv1.0.16.pl input1 [-y]

input parameters:
1. input1 the input file with tab-delimted pubmed id, title and abstract in a plain text form.
2. [-y] optional argument. With this option, EMU processes the input text by sentences.


A3 SEQ_filter:
^^^^^^^^^^^^^^^^^^
the seq_filter parser: 

syntax:
perl EMU_seq_filter.pl <input_file> <output_file>

the input file is the ouput from EMU.
This method needs internet connection. It retrieves data from the NCBI server.


Example: 
^^^^^^^^^
let the PCA_abst_mutation.txt be the input file for EMU that contains the abstracts
perl EMUv1.0.16.pl PCA_abst_mutation.txt
perl EMUv1.0.16.pl PCA_paper.txt -y		//application of EMU on full paper text (instead of just abstract) and runs EMU on sentences
perl EMU_seq_filter.pl EMU_1.16_HUGO_PCA_abst_mutation.txt EMU_1.16_HUGO_PCA_abst_mutation_SF.txt




specification of the input files:
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
All files are tab-delimited.

the input file of the EMU has to look like:
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
pmid	title	abstract
10021378	Alzheimer's disease: clues from flies and worms.	Presenilin mutations give rise to familial Alzheimer's disease and result in elevated production of amyloid beta peptide. Recent evidence that presenilins act in developmental signalling pathways may be the key to understanding how senile plaques, neurofibrillary tangles and apoptosis are all biochemically linked.
.
.
.

the output of the EMU and the input of the fasta check is:
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
pmid	organism	mut_pat1	pos_patt	wtaa	mtaa	pos	genes	type
15146458	Humans	 g.4870T>C 		T	C	4870	ANP32A;ANP32C;PC	GENOM
.
.
.

the ouput of the seq_filter
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
pmid	organism	mut_pat1	pos_patt	wtaa	mtaa	pos	genes	type	fasta_check	gi	gene_name	prot_id
10517877	Humans	 histidine to aspartic acid.	codon 1104	HIS	ASP	1104	ERCC5	PROTEIN	YES	2073	ERCC5	51988900|REV
.
.
.





