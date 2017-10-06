function MergesCreateTime(filename)

load(filename, 'resdata')
indices = MergesRes(resdata);
writetable(indices, 'indices.csv', 'Encoding', 'UTF-8')
save indices indices
end

function indices = MergesRes(resdata)

% all the possible metavars
VARNAMES = {'Taskname', 'excerciseId', 'userId', 'name', 'sex', 'school', 'grade', 'cls', 'birthDay', 'createTime', 'index'};
indices = cellfun(@(tbl) tbl(:, VARNAMES), resdata.Data, 'UniformOutput', false);
indices = cat(1, indices{:});
end
