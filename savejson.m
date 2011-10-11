function json=savejson(rootname,obj,varargin)
%
% json=savejson(rootname,obj,opt)
%
% convert a MATLAB object (cell, struct or array) into a JSON (JavaScript
% Object Notation) string
%
% authors:Qianqian Fang (fangq<at> nmr.mgh.harvard.edu)
%            date: 2011/09/09
%
% input:
%      rootname: name of the root-object, if set to '', will use variable name
%      obj: a MATLAB object (array, cell, cell array, struct, struct array)
%      opt: a struct for additional options, use [] if all use default
%        opt can have the following fields (first in [.|.] is the default)
%        opt.FloatFormat ['%.10g'|string]: format to show each numeric element
%                         of a 1D/2D array;
%        opt.ArrayIndent [1|0]: if 1, output explicit data array with
%                         precedent indentation; if 0, no indentation
%        opt.ArrayToStruct[0|1]: when set to 0, savejson outputs 1D/2D
%                         array in JSON array format; if sets to 1, an
%                         array will be shown as a struct with fields
%                         "_ArrayType", "_ArraySize" and "_ArrayData"; for
%                         sparse arrays, the non-zero elements will be
%                         saved to _ArrayData field in triplet-format i.e.
%                         (ix,iy,val) and "_ArrayIsSparse" will be added
%                         with a value of 1.
%
% output:
%      json: a string in the JSON format (see http://json.org)
%
% examples:
%      a=struct('node',[1  9  10; 2 1 1.2], 'elem',[9 1;1 2;2 3],...
%           'face',[9 01 2; 1 2 3; NaN,Inf,-Inf], 'author','FangQ');
%      savejson('mesh',a)
%      savejson('',a,struct('ArrayIndent',0,'FloatFormat','\t%.5g'))
%
% -- this function is part of iso2mesh toolbox (http://iso2mesh.sf.net)
%

varname=inputname(2);
if(~isempty(rootname))
   varname=rootname;
end
rootisarray=0;
rootlevel=1;
if((isnumeric(obj) || islogical(obj) || ischar(obj)) && isempty(rootname))
    rootisarray=1;
    rootlevel=0;
    varname='';
end
json=obj2json(varname,obj,rootlevel,varargin{:});
if(rootisarray)
    json=sprintf('%s\n',json);
else
    json=sprintf('{\n%s\n}\n',json);
end

%%-------------------------------------------------------------------------
function txt=obj2json(name,item,level,varargin)

cname=class(item);

if(iscell(item))
    txt=cell2json(name,item,level,varargin{:});
elseif(isstruct(item))
    txt=struct2json(name,item,level,varargin{:});
elseif(ischar(item))
    txt=str2json(name,item,level,varargin{:});
else
    txt=mat2json(name,item,level,varargin{:});
end

%%-------------------------------------------------------------------------
function txt=cell2json(name,item,level,varargin)
txt='';
if(~iscell(item))
        error('input is not a cell');
end

dim=size(item);
len=numel(item); % let's handle 1D cell first
padding1=repmat(sprintf('\t'),1,level-1);
padding0=repmat(sprintf('\t'),1,level);
if(len>1) txt=sprintf('%s"%s": [\n',padding0, name); name=''; end
for i=1:len
    txt=sprintf('%s%s%s',txt,padding1,obj2json(name,item{i},level+(len>1),varargin{:}));
    if(i<len) txt=sprintf('%s%s',txt,sprintf(',\n')); end
end
if(len>1) txt=sprintf('%s\n%s]',txt,padding0); end

%%-------------------------------------------------------------------------
function txt=struct2json(name,item,level,varargin)
txt='';
if(~isstruct(item))
	error('input is not a struct');
end
len=numel(item);
padding1=repmat(sprintf('\t'),1,level);
padding0=repmat(sprintf('\t'),1,level+1);
sep=',';

if(~isempty(name)) 
    if(len>1) txt=sprintf('%s"%s": [\n',padding1,name); end
else
    if(len>1) txt=sprintf('%s[\n',padding1); end
end
for e=1:len
  names = fieldnames(item(e));
  if(~isempty(name) && len==1)
        txt=sprintf('%s%s"%s": {\n',txt,padding1, name); 
  else
        txt=sprintf('%s%s{\n',txt,padding1); 
  end
  if(~isempty(names))
    for i=1:length(names)
	    txt=sprintf('%s%s',txt,obj2json(names{i},getfield(item(e),...
             names{i}),level+1+(len>1),varargin{:}));
        if(i<length(names)) txt=sprintf('%s%s',txt,','); end
        txt=sprintf('%s%s',txt,sprintf('\n'));
    end
  end
  txt=sprintf('%s%s}',txt,repmat(sprintf('\t'),1,level+(len>1)));
  if(e==len) sep=''; end
  if(e<len) txt=sprintf('%s%s',txt,sprintf(',\n')); end
end
if(len>1) txt=sprintf('%s\n%s]',txt,padding1); end

%%-------------------------------------------------------------------------
function txt=str2json(name,item,level,varargin)
txt='';
if(~ischar(item))
        error('input is not a string');
end
len=size(item,1);
sep=sprintf(',\n');

padding1=repmat(sprintf('\t'),1,level);
padding0=repmat(sprintf('\t'),1,level+1);

if(~isempty(name)) 
    if(len>1) txt=sprintf('%s"%s": [\n',padding1,name); end
else
    if(len>1) txt=sprintf('%s[\n',padding1); end
end
for e=1:len
    val=regexprep(item(e,:),'([^\\])"','$1\\"');
    val=regexprep(val,'^"','\\"');
    if(len==1)
        obj=['"' name '": ' '"',val,'"'];
	if(isempty(name)) obj=['"',val,'"']; end
        txt=sprintf('%s%s%s%s',txt,repmat(sprintf('\t'),1,level),obj);
    else
        txt=sprintf('%s%s%s%s',txt,repmat(sprintf('\t'),1,level+1),['"',val,'"']);
    end
    if(e==len) sep=''; end
    txt=sprintf('%s%s',txt,sep);
end
if(len>1) txt=sprintf('%s\n%s%s',txt,padding1,']'); end

%%-------------------------------------------------------------------------
function txt=mat2json(name,item,level,varargin)
if(~isnumeric(item) && ~islogical(item))
        error('input is not an array');
end

padding1=repmat(sprintf('\t'),1,level);
padding0=repmat(sprintf('\t'),1,level+1);

if(length(size(item))>2 || issparse(item) || jsonopt('ArrayToStruct',0,varargin{:}))
    if(isempty(name))
    	txt=sprintf('%s{\n%s"_ArrayType": "%s",\n%s"_ArraySize": %s,\n',...
              padding1,padding0,class(item),padding0,regexprep(mat2str(size(item)),'\s+',',') );
    else
    	txt=sprintf('%s"%s": {\n%s"_ArrayType": "%s",\n%s"_ArraySize": %s,\n',...
              padding1,name,padding0,class(item),padding0,regexprep(mat2str(size(item)),'\s+',',') );
    end
else
    if(isempty(name))
    	txt=sprintf('%s%s',padding1,matdata2json(item,level+1,varargin{:}));
    else
    	txt=sprintf('%s"%s": %s',padding1,name,matdata2json(item,level+1,varargin{:}));
    end
    return;
end
dataformat='%s%s%s%s%s';

if(issparse(item))
    [ix,iy]=find(item);
    txt=sprintf(dataformat,txt,padding0,'"_ArrayIsSparse": ','1', sprintf(',\n'));
    if(find(size(item)==1))
        txt=sprintf(dataformat,txt,padding0,'"_ArrayData": ',...
           matdata2json([ix,full(item(find(item)))],level+2,varargin{:}), sprintf('\n'));
    else
        txt=sprintf(dataformat,txt,padding0,'"_ArrayData": ',...
           matdata2json([ix,iy,full(item(find(item)))],level+2,varargin{:}), sprintf('\n'));
    end
else
    txt=sprintf(dataformat,txt,padding0,'"_ArrayData": ',...
        matdata2json(item(:)',level+2,varargin{:}), sprintf('\n'));
end
txt=sprintf('%s%s%s',txt,padding1,'}');

%%-------------------------------------------------------------------------
function txt=matdata2json(mat,level,varargin)
if(size(mat,1)==1)
    pre='';
    post='';
    level=level-1;
else
    pre=sprintf('[\n');
    post=sprintf('\n%s]',repmat(sprintf('\t'),1,level-1));
end
if(isempty(mat))
    txt='null';
    return;
end
floatformat=jsonopt('FloatFormat','%.10g',varargin{:});
formatstr=['[' repmat([floatformat ','],1,size(mat,2)-1) [floatformat sprintf('],\n')]];

if(nargin>=2 && size(mat,1)>1 && jsonopt('ArrayIndent',1,varargin{:}))
    formatstr=[repmat(sprintf('\t'),1,level) formatstr];
end
txt=sprintf(formatstr,mat');
txt(end-1:end)=[];
%txt=regexprep(mat2str(mat),'\s+',',');
%txt=regexprep(txt,';',sprintf('],\n['));
% if(nargin>=2 && size(mat,1)>1)
%     txt=regexprep(txt,'\[',[repmat(sprintf('\t'),1,level) '[']);
% end
txt=[pre txt post];
if(any(isinf(mat(:))))
    txt=regexprep(txt,'([-+]*)Inf','"$1_Inf"');
end
if(any(isnan(mat(:))))
    txt=regexprep(txt,'NaN','"_NaN"');
end

%%-------------------------------------------------------------------------
function val=jsonopt(key,default,varargin)
val=default;
if(nargin<=2) return; end
opt=varargin{1};
if(isstruct(opt) && isfield(opt,key))
    val=getfield(opt,key);
end