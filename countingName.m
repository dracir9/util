function strName = countingName(prefix)
    %  Get all files starting with prefix
    names = cellstr(ls([prefix '*']));

    % Find files ending with underscore and a number
    numStr = regexp(names, '_\d+\>', 'Match');

    % Delete cells where no match was found
    numStr = numStr(~cellfun('isempty', numStr));
    num = zeros(1, numel(numStr));
    for ii = 1:numel(numStr)
        A = numStr{ii};

        % If there is more than one match get the last one
        % Delete the underscore
        A{end}(1) = [];

        if isempty(A{end})
            continue
        else
            num(ii) = str2double(A{end});
        end
    end
    if (isempty(num))
        strName = [prefix '_00'];
    else
        strName = [prefix '_' num2str(max(num)+1, '%02d')];
    end  
end