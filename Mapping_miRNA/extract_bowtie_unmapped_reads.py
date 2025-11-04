# python extract_bowtie_unmapped_reads.py -fq bowtie_input.fastq -mapped bowtie_mapped.txt -out bowtie_unmapped.fastq


#### get mapped read ####
def bowtie_mapped(file):
	mapped = set()
        with open(file, 'r') as f:
		l = f.readline()
		while l:
			mapped.add( l.split('\t')[2].split('#')[0] )
			l = f.readline()
        return list(mapped)	# list of mapped read


#### read fastq file ####
def extract_unmapped_reads(file, mapped):
	unmapped = {}
        with open(file, 'r') as f:
                l = f.readline()
                while l:
                        if l[0] == '@':
				data = l		# read name
                                seq = f.readline().rstrip('\n\r\a')
				data += seq + '\n'	# sequence
				data += f.readline()	# strand
				data += f.readline()	# Q-score

				if unmapped.has_key(seq):
					unmapped[seq][0] += data
				else:
					unmapped[seq] = [data]
                        l = f.readline()

	for s in mapped:	# discard mapped reads
		del unmapped[s]

	return unmapped


import argparse

parser = argparse.ArgumentParser(usage='python extract_bowtie_unmapped_reads.py [options] -fq bowtie_input.fastq -mapped bowtie_mapped.txt -out bowtie_unmapped.fastq')
parser.add_argument('-fq', metavar='in.fq', required=True, help='fastq format file used for bowtie mapping.')
parser.add_argument('-mapped', metavar='mapped.txt', required=True, help='Default output file from bowtie.')
parser.add_argument('-out', metavar='unmapped.fq', required=True, help='Output file name.')
p = vars(parser.parse_args())

mapped_reads = bowtie_mapped( p['mapped'] )
unmapped_reads = extract_unmapped_reads( p['fq'], mapped_reads )

with open( p['out'], 'w' ) as f:
	for data in unmapped_reads.values():
		f.write( ''.join(data[0]) )
