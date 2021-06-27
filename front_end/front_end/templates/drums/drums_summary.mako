<%
    import sys
    sys.path.append('/home/zuofeng/projects/platform/bminfo/bminfo/scripts')
    from ppMapDB import ppMapMySQL
    pp = ppMapMySQL('bminfo')
    sql = 'select count(*) from GENOTYPE_PHENOTYPE_PRODUCT WHERE data_status ="init"'
    uniqueMutUrls = pp.execute(sql)
    
    sql = 'select count(*) from DRUMS_SEQS'
    uniqueMutSeqs = pp.execute(sql)
    
%>
refer to <a href="http://www.hgmd.org/">http://www.hgmd.org/</a><p>
<table>
    <tr>
        <td>mutations with unique urls</td>
        <td>${uniqueMutUrls}</td>
    </tr>
    <tr>
        <td>mutations with unique sequences</td>
        <td>${uniqueMutSeqs}</td>
    </tr>
</table>