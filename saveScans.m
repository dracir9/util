function saveScans(file, scans)
    try
        iteration = cell(1,numel(scans));
        
        for ii = 1:numel(iteration)
            data = scans{ii};
            data.pts(2,:) = -data.pts(2,:);
            iteration{ii}.scan = data.pts;

            if isfield(data, 'enc')
                iteration{ii}.encStep = data.enc;
            end
        end

        save(file, 'iteration');
    catch e
        util.printStack(e)
    end
end