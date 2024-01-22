classdef Logger < handle
    %LOGGING Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = private)
        handle
        tmr
    end

    properties (SetAccess = private)
        type
        id
    end

    properties
        level
        format
    end

    methods (Access = ?util.Logging)
        function obj = Logger(id, type, hdle, level, format)
            %LOGGING Construct an instance of this class
            %   Detailed explanation goes here

            % Check inputs
            util.Logging.checkLevel(level);

            switch type
                case 'cmd'
                    hdle = [];
                case 'gfx'
                    if ~isgraphics(hdle)
                        error('Handle input must be a graphic object for type ''gfx''')
                    elseif ~isprop(hdle, 'String')
                        error('Loggin is not supported for graphic object of type %s. I must have a field named String', hdle.Type)
                    end
                case 'file'
                    hdle = char(hdle);
                    idx = find(hdle == '/' | hdle == '\', 1, 'last');
                    if ~isempty(idx) 
                        folderName = hdle(1:idx);
                        if ~exist(folderName, 'dir')
                            mkdir(folderName)
                        end
                    end
                    fName = [hdle '.log'];
                    hdle = fopen(fName, 'A');
                    if hdle == -1
                        error('Could not open or create file at ''%s''', fName)
                    end

                    % Add creation time
                    fprintf(hdle, 'T = %s\n', char(datetime));
                otherwise
                    error('Invalid Logger type %s', type)
            end

            % Initialize properties
            obj.id = id;
            obj.type = type;
            obj.handle = hdle;
            obj.level = level;
            obj.format = format;

            % Initialize timer
            obj.tmr = tic;
        end

        function print(obj, L, txt)
            for log = obj
                if util.Logging.level2Num(L) <= util.Logging.level2Num(log.level)
                    switch log.type
                        case 'cmd'
                            fprintf(log.format, L, txt);
                        case 'file'
                            fprintf(log.handle, ['T+%08.3f ' log.format], toc(log.tmr), L, txt);
                        case 'gfx'
                            if isvalid(log.handle)
                                log.handle.String = sprintf(log.format, L, txt);
                            end
                    end
                end
            end
        end
    end

    methods
        function delete(obj)
            if strcmp(obj.type, 'file')
                fclose(obj.handle);
            end
        end

        function set.level(obj, val)
            util.Logging.checkLevel(val);
            obj.level = val;
        end
    end

    methods (Static)
        function outTxt = error(obj, varargin)
            if isa(obj, 'util.Logging')
                if isa(varargin{1}, 'MException')
                    txt = obj.loggers.printStack(varargin{1});
                    obj.loggers.print('E', txt);
    
                    if nargin > 2
                        txt = sprintf(varargin{2:end});
                        obj.loggers.print('E', txt);
                    end
                else
                    txt = sprintf(varargin{:});
                    obj.loggers.print('E', txt);
                end
            else
                loggers = util.Logging.getLoggers();
                if ~isempty(loggers)
                    if isa(obj, 'MException')
                        txt = loggers.printStack(obj);
                        loggers.print('E', txt);
        
                        if nargin > 1
                            txt = sprintf(varargin{:});
                            loggers.print('E', txt);
                        end
                    else
                        txt = sprintf(obj, varargin{:});
                        loggers.print('E', txt);
                    end
                else
                    if isa(obj, 'MException')
                        txt = loggers.printStack(obj);
                        fprintf('E: %s\n', txt);
        
                        if nargin > 1
                            txt = sprintf(varargin{:});
                            fprintf('E: %s\n', txt);
                        end
                    else
                        txt = sprintf(obj, varargin{:});
                        fprintf('E: %s\n', txt);
                    end
                end
            end

            if nargout > 0
                outTxt = txt;
            end
        end

        function outTxt = warning(obj, varargin)
            txt = util.Logger.print_('W', obj, varargin);

            if nargout > 0
                outTxt = txt;
            end
        end

        function outTxt = info(obj, varargin)
            txt = util.Logger.print_('I', obj, varargin);

            if nargout > 0
                outTxt = txt;
            end
        end

        function outTxt = debug(obj, varargin)
            txt = util.Logger.print_('D', obj, varargin);

            if nargout > 0
                outTxt = txt;
            end
        end

        function outTxt = trace(obj, varargin)
            txt = util.Logger.print_('T', obj, varargin);

            if nargout > 0
                outTxt = txt;
            end
        end

        function str = printStack(e)
            str = sprintf('%s\n', e.message);
            for ii = 1:numel(e.stack)
                stk = e.stack(ii);
                bkslshPos = find(stk.file == '\', 1, 'last');
                dotPos = find(stk.file == '.', 1, 'last');
        
                file = stk.file(bkslshPos+1:dotPos-1);
                if strcmp(file, stk.name)
                    str = sprintf('%s\tIn file <a href="matlab: opentoline(''%s'', %d)">%s</a> (line %d)\n', ...
                        str, stk.file, stk.line, file, stk.line);
                else
                    str = sprintf('%s\tIn file <a href="matlab: opentoline(''%s'', %d)">%s>%s</a> (line %d)\n', ...
                        str, stk.file, stk.line, file, stk.name, stk.line);
                end
            end
        end
    end

    methods (Access = protected, Static)
        function txt = print_(level, obj, args)
            if isa(obj, 'util.Logging')
                txt = sprintf(args{:});
                obj.loggers.print(level, txt);
            else
                txt = sprintf(obj, args{:});
                loggers = util.Logging.getLoggers();
                if ~isempty(loggers)
                    loggers.print(level, txt);
                else
                    fprintf('%c: %s\n', level, txt);
                end
            end
        end
    end
end
