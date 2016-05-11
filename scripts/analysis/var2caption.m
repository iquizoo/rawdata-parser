function [titlevar, label] = var2caption(task, varname)
%VAR2CAPTION converts varname into useful caption in figures.

varnamesplit = strsplit(varname, '_');
varnamesplit = strrep(varnamesplit, 'prime', '''');
if length(varnamesplit) > 1
    lbswtchtasks = {'PicMemory', 'WordMemory'}; %Label switch tasks.
    if ismember(task, lbswtchtasks)
        label = varnamesplit{2};
    else
        if strcmp(varnamesplit{2}, 'Overall')
            varnamesplit{1} = strrep(varnamesplit{1}, 'Rate', 'ACC');
        end
        label = varnamesplit{1};
    end
else
    label = varnamesplit{1};
end
titlevar = strjoin(varnamesplit, ' ');
label = strrep(label, 'RT', 'RT(ms)');
