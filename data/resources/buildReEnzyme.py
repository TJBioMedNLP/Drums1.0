import sys
#http://rebase.neb.com/cgi-bin/asymmlist
sys.path.append('/home/zuofeng/projects/platform/bminfo/bminfo/scripts')
import ground as gd

renzymeFile = '/home/zuofeng/projects/platform/bminfo/data/mutations/resources/renzyme.tsv'
fout = open('/home/zuofeng/projects/platform/bminfo/data/mutations/resources/renzyme_transformed.tsv', 'w')
restrEnzymes = {} # = {'Nsp I':'[AG]CATG[TC]','Sty I':'CC[AT][AT]GG', 'Nsp V':'TTCGAA'}
for line in open(renzymeFile, 'r').readlines():
    fds = line.split('\t')
    pattern = fds[1]
    print pattern + '---'
    try:
        reEx= ''
        for iupac in pattern:
            print iupac
            bases = gd.getBasesFromIUPAC(iupac)
            if len(bases) ==1:
                reEx += bases[0]
            elif len(bases) == 0:
                raw_input('something error')
            else:
                reEx += '[' + ''.join(bases) + ']'
        fds[1] = reEx
    except:
        continue
    
    
    
    fout.write('\t'.join(fds))
fout.close()