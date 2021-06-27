<%
    import sys, urllib2
    sys.path.append('/data_pool/home/zuofeng/projects/platform/bminfo/bminfo/scripts')
    from ppMapDB import ppMapMySQL
    pp = ppMapMySQL('bminfo')
    
    pars = request.POST
    if len(pars.keys()) == 0:
        pars = request.params
        
    category = None
    qterm = ''
    if pars.has_key('c'):
        category = pars['c']
    if pars.has_key('t'):
        qterm = pars['t']
    
    print qterm
    mutids = []
    if not category:    
        return
    print category
    if category == 'gsymb':
        pass
    elif category == 'dis':
        pass
    elif category == 'lsdb':
        pass
    elif category == 'pmid':
        pass
    elif category == 'disease':
        pass
    elif category == 'mtid':
        mutids = qterm.split(',')
    print mutids
%>
% if len(mutids) == 1:
    <%include file="digest.mako"/>
% else:
    <%include file="adv_search.mako"/>
% endif
