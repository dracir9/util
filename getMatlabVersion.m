function v = getMatlabVersion()
    str = version('-release');
    v = str2double(str(1:end-1));

    if str(end) == 'b'
        v = v + 0.5;
    elseif str(end) ~= 'a'
        error('Unknown Matlab version: %s', str);
    end
end