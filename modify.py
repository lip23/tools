!/usr/bin/env python                                                                                            
                                                                                
import sys                                                                      
import re                                                                       
import os                                                                       
import getopt                                                                   
import ConfigParser                                                             
                                                                                
                                                                                
# platforms                                                                     
ps = ['A', 'R', 'Z'] + ['r' + chr(i) for i in xrange(ord('a'), ord('l'))] + \
     ['z' + chr(i) for i in xrange(ord('a'), ord('l'))]                         
                                                                                
                                                                                
# b:bin num, fn:file name                                                       
def AlterBin(b, fn):                                                            
    f = open(fn, 'r+')                                                          
    s = f.readline()                                                            
    if None == re.search(r'/\d+/', s):                                          
        return f.close()                                                        
    n = int((re.search(r'/\d+/', s).group())[1:-1])                             
    if b > n:                                                                   
        f.seek(0)                                                               
        f.write(s.replace(str(n), str(b)))                                      
        print(fn + '  alter bin: ' + str(n) + '--->' + str(b))                  
    return f.close()                                                            
                                                                                
                                                                                
# g:gflag, fn:file name                                                         
def AlterGflag(g, fn):                                                          
    f = open(fn, 'a+')                                                          
    s = '-' + g + '=true\n'                                                     
    for l in f.readlines():                                                     
        if s == l:                                                              
            return f.close()                                                    
    f.write(s)                                                                  
    print(fn + '  add gflag: ' + s[0:-1])                                       
    return f.close()                                                            
                                                                                
                                                                                
# s:section, k:key, v:value, p:pos, m:comment, fn:file name                     
def AlterIni(s, k, v, p, m, fn):                                                
  f = open(fn,'r+')                                                             
  ls = f.readlines()                                                            
  for i in xrange(ls.index('[' + s + ']\n'), len(ls)):                          
      if p == '' or re.match(p + '\s*=', ls[i]) != None:                        
          if p == k:                                                            
              ls[i] = k + ' = ' + v + '\n'                                      
          else:                                                                 
              ls.insert(i + 1, k + ' = ' + v + '\n')                            
          if m != '':                                                           
              ls.insert(i + 1, '# ' + m + '\n')                                 
          f.seek(0)                                                             
          f.writelines(ls)                                                      
          print(fn + '  alter ini: [' + s + '] ' + k + ' = ' + v)               
          return f.close()                                                      
  return f.close()       


def AlterBinForPlatform(b, p):                                                     
    for pa in p:                                                                   
        fn = pa + '/bin.des'                                                       
        AlterBin(b,fn)                                                             
    return                                                                         
                                                                                   
                                                                                   
def AlterGflagForPlatform(g, p):                                                   
    for pa in p:                                                                   
        fn = pa + '/ad_server.gflags'                                              
        AlterGflag(g,fn)                                                           
    return                                                                         
                                                                                   
                                                                                   
def CheckSectionAndKeys(d, fn):                                                    
    cf = ConfigParser.ConfigParser()                                               
    cf.read(fn)                                                                    
    if cf.has_section(d['-s']) == False:                                           
        print('no proper section\n')                                               
        return False                                                               
    if cf.has_option(d['-s'], d['-k']):                                            
        d['-P'] = d['-k']                                                          
    elif '-P' in d and cf.has_option(d['-s'], d['-P']) == False:                   
        print('no proper pos key\n')                                               
        return False                                                               
    elif '-P' not in d:                                                            
        d['-P'] = ''                                                               
    if '-m' not in d:                                                              
        d['-m'] = ''                                                               
    return True                                                                    
                                                                                   
                                                                                   
def AlterIniForPlatform(d, p):                                                     
    for pa in p:                                                                   
        fn = pa + '/query_server.ini'                                              
        da = d.copy()                                                              
        if CheckSectionAndKeys(da, fn):                                            
            AlterIni(da['-s'], da['-k'], da['-v'], da['-P'], da['-m'], fn)         
    return                                                                         
                                                                                   
                                                                                   
def GetPlatform(p):                                                                
    if p == 'A':                                                                   
        return ['r' + chr(i) for i in xrange(ord('a'), ord('l'))] +\
               ['z' + chr(i) for i in xrange(ord('a'), ord('l'))]                  
    elif p == 'R' or p == 'Z':                                                     
        return [p.lower() + chr(i) for i in xrange(ord('a'), ord('l'))]            
    return [p]  


def PrintHelpInfo():                                                            
    h="\n\
        -h help\n\
        -p platform, za, R for all r, Z for all z, A for all(eg za, R)\n\
        -b alter bin num (eg 166)\n\
        -g add gflag (eg ucc_enable)\n\
        -s add 'key=value' in section\n\
           if key exist, update value \n\
        -k key\n\
        -v value\n\
        -P pos, where key insert behind pos\n\
           if pos == '', key insert behind the section\n\
        -m commet\n"
    print(h)                                                                    
                                                                                
                                                                                
def DoAlter(d):                                                                 
    p = GetPlatform(d['-p'])                                                    
    if '-b' in d:                                                               
        AlterBinForPlatform(int(d['-b']), p)                                    
    if '-g' in d:                                                               
        AlterGflagForPlatform(d['-g'], p)                                       
    if '-s' in d:                                                               
        AlterIniForPlatform(d, p)                                               
    if '-h' in d:                                                               
        PrintHelpInfo()                                                         
    return 


def CheckArgument(d):                                                              
    if '-p' not in d or d['-p'] not in ps:                                         
        print('no proper platform')                                                
        return False                                                               
    if '-b' in d and d['-b'].isdigit() == False:                                   
        print('no proper bin num')                                                 
        return False                                                               
    if '-s' in d and ('-k' not in d or '-v' not in d):                             
        print('no proper key or value')                                            
        return False                                                               
    return True                                                                 
                                                                                
                                                                                
def Main(argv):                                                                 
    try:                                                                        
        opts, args = getopt.getopt(argv, "hp:b:g:s:k:v:P:m:")                   
        d = {opt:arg for opt, arg in opts}                                      
        if CheckArgument(d):                                                    
            DoAlter(d)                                                          
    except getopt.GetoptError:                                                  
        PrintHelpInfo()                                                         
    return                                                                      
                                                                                
                                                                                
if __name__ == '__main__':                                                      
    Main(sys.argv[1:]) 
