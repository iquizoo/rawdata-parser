function mrg = Merges(res)
%Merges merge index to metadata for all the tasks and subjects.

ntasks = height(res);
results = cell(ntasks, 1);
for itask = 1:ntasks
    if ~isempty(res.Results{itask})
        curtask_results = outerjoin(res.Meta{itask}, res.Results{itask}, ...
            'MergeKeys', true, 'RightVariables', {'indexName', 'index'});
        curtask_results.taskIDName = repmat(res.TaskIDName(itask), ...
            height(curtask_results), 1);
        results{itask} = curtask_results;
    end
end
% concatenate results
mrg = cat(1, results{:});
