classdef Logger < handle
    %LOGGING Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = private)
        handle
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
                    hdle = fopen(fName, 'a');
                    if hdle == -1
                        error('Could not open or create file at ''%s''', fName)
                    end
                otherwise
                    error('Invalid Logger type %s', type)
            end

            % Initialize properties
            obj.id = id;
            obj.type = type;
            obj.handle = hdle;
            obj.level = level;
            obj.format = format;
        end

        function print(obj, L, txt)
            for log = obj
                if util.Logging.level2Num(L) <= util.Logging.level2Num(log.level)
                    switch log.type
                        case 'cmd'
                            fprintf(log.format, L, txt);
                        case 'file'
                            fprintf(log.handle, ['%s ' log.format], char(datetime), L, txt);
                        case 'gfx'
                            log.handle.String = sprintf(log.format, L, txt);
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
            txt = util.Logger.print_('E', obj, varargin);

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
