<%include file="../bminfo_header.html"/>
<%
    import sys
    sys.path.append('/home/zuofeng/projects/platform/bminfo/bminfo/scripts')
    from ppMapDB import ppMapMySQL
    pp = ppMapMySQL('bminfo')
    #             0          1       2          3         4            5               6        
    sql = 'select unique_id, status, drums_url, hgvs_url, gene_symbol, drums_progress, copr_reqst from lsdb_list ORDER BY copr_reqst ASC,drums_progress DESC,  drums_url DESC'
    lines = pp.execute(sql)
    
    showOrder = [6,0,5,1,4,2]
    fields = ['unique_id', 'status', 'drums_url', 'hgvs_url', 'gene_symbol', 'drums_progress', 'copr_reqst']
    fieldAliasNames =['unique_id', 'status', 'drums_url', 'hgvs_url', 'gene_symbol', 'drums_progress', 'copy right request']
    
    clientid = 0
    
%>
%if len(lines) > 0:
<head>
    <script src="../jquery/extension/jquery.tablesorter-2.0.3.js" type="text/javascript"></script>
    <script src="../jquery/extension/jquery.tablesorter.filer.js" type="text/javascript"></script>
    <script src="../jquery/extension/jquery.tablesorter.pager.js" type="text/javascript"></script>

    <script>
        function downloadDrums(size){
            if (size< 1){
                $( "#pagesize" ).val("${len(lines)}");
                $( "#pagesize" ).change();
            }
            
            //$("#pagesize option[value='334']").get(0).selected = true;
            
            isDirty = false;
            var csv_value = $('#drumsTable').table2CSV({
                            separator : '\t',
                            delivery:'value',
                            quote: '',
                            });
            $("#data").val(csv_value);
            //alert(data)
        }
    </script>
</head>
 
<script type="text/javascript">

    
            //known issues: sorting function conficts with google chrome plugin: google dictionary.
            $("#drumsTable").tablesorter({ debug: false, sortList: [[0, 0]], widgets: ['zebra'] })
                        .tablesorterPager({ container: $("#pagerOne"), positionFixed: false })
                        .tablesorterFilter({ filterContainer: $("#filterBoxOne"),
                            filterClearContainer: $("#filterClearOne"),
                            filterColumns: [0, 1, 2, 4,5,6],
                            filterCaseSensitive: false

                        }); 
    </script>   
  


    <table id="drumsTable" class="yui">
            <thead>
                <tr>
                    
                     %if clientid > 0:
                        <form action="http://autumn.ims.uwm.edu:5000/data/download" method="POST">
                    %else:
                        <form action="../data/download" method="POST">
                    %endif
                    <td>
                    </td>
                    
                            <input type="hidden" name="data" id="data"/>
                            <td id="profileTypeTd" class="tableHeader">
                            <input type="submit" value="dowload showing entries" onclick="downloadDrums(1)"/>
                            </td>
                            <td id="profileTypeTd" class="tableHeader">
                            <input type="submit" value="dowload all ${len(lines)} entries" onclick="downloadDrums(0)"/>
                            </td>
                        
                    
                    </td>
                    </form>

                    <td colspan="12" class="filter">
                        Filter hits: <input id="filterBoxOne" value="" maxlength="30" size="30" type="text">
                        <img id="filterClearOne" src="../img/cross.png" title="Click to clear filter." alt="Clear Filter Image">
                    </td>
                 </tr> 
            <tr>
                <th class="header"><a href="." title="Click Header to Sort">index</a></th>
                %for i in showOrder:
                    <th class="header"><a href="." title="Click Header to Sort">${fieldAliasNames[i]}</a></th>
                %endfor
            </tr>
        </thead>
        <tbody>
            % for index in range(len(lines)):
                <%
                    line = lines[index]
                %>
                
                
                <tr>

                    <td>${index + 1}</td>
                    <td>${line[6]}</td>
                    <td><a href="http://autumn.ims.uwm.edu:5000/mutation/lsdb?r=mt&uid=${line[0]}" target="_blank">${line[0]}<img src="../img/structure/lock_small.jpg"/></a></td>
                    <td title="curation progress">${line[5]}%</td>
                    <td>${line[1]}</td>
                    <td>${line[4]}</td>
                    % if line[2] == '-' or not line[2]:
                        <td><a href="${line[3]}" target="_blank">${line[3]}</a></td>
                    % else:
                        <td><a href="${line[2]}" target="_blank">${line[2]}</a></td>
                    % endif   
                </tr>
            % endfor

        </tbody>

        <tfoot>
            <tr id="pagerOne">
                <td colspan="7" >
                    <img src="../img/first.png" class="first">
                    <img src="../img/prev.png" class="prev">
                    <input type="text" class="pagedisplay">
                    <img src="../img/next.png" class="next">
                    <img src="../img/last.png" class="last">
                    <select id="pagesize" class="pagesize">
                        <option value="10">10</option>
                        <option selected="selected" value="20">20</option>
                        <option value="30">30</option>
                        <option  value="50">50</option>
                        <option  value="100">100</option>
                        <option  value="${len(lines)}">All</option>
                    </select>
                </td>

            </tr>
        </tfoot>  

    </table>
<script type="text/javascript" src="../jquery/extension/table2CSV.js" > </script>
%else:
    No results matching your query.
%endif
