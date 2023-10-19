function printStack(e)
    fprintf('Error: %s\n', e.message)
    for ii = 1:numel(e.stack)
        stk = e.stack(ii);
        bkslshPos = find(stk.file == '\', 1, 'last');
        dotPos = find(stk.file == '.', 1, 'last');

        file = stk.file(bkslshPos+1:dotPos-1);
        if strcmp(file, stk.name)
            fprintf('\tIn file <a href="matlab: opentoline(''%s'', %d)">%s</a> (line %d)\n', ...
                stk.file, stk.line, file, stk.line)
        else
            fprintf('\tIn file <a href="matlab: opentoline(''%s'', %d)">%s>%s</a> (line %d)\n', ...
                stk.file, stk.line, file, stk.name, stk.line)
        end
    end
end