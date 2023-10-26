classdef logger < handle
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

    methods (Access = ?util.logging)
        function obj = logger(id, type, hdle, level, format)
            %LOGGING Construct an instance of this class
            %   Detailed explanation goes here

            % Check inputs
            util.logging.checkLevel(level);

            switch type
                case 'cmd'
                    hdle = [];
                case 'gfx'
                    if ~isgraphics(hdle)
                        error('Handle input must be a graphic object for type ''gfx''')
                    elseif ~isfield(hdle, 'String')
                        error('Unsupported graphic object. I must have a field named String')
                    end
                case 'file'
                    hdle = fopen([hdle '.log'], 'a');
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
                if util.logging.level2Num(L) <= util.logging.level2Num(log.level)
                    txtFormated = sprintf(log.format, L, txt);
                    switch log.type
                        case 'cmd'
                            fprintf(txtFormated);
                        case 'file'
                            fprintf(log.handle, txtFormated);
                        case 'gfx'
                            log.handle.String = txtFormated;
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
            util.logging.checkLevel(val);
            obj.level = val;
        end
    end

    methods (Static)
        function outTxt = error(obj, varargin)
            txt = util.logger.print_('E', obj, varargin);

            if nargout > 0
                outTxt = txt;
            end
        end

        function outTxt = warning(obj, varargin)
            txt = util.logger.print_('W', obj, varargin);

            if nargout > 0
                outTxt = txt;
            end
        end

        function outTxt = info(obj, varargin)
            txt = util.logger.print_('I', obj, varargin);

            if nargout > 0
                outTxt = txt;
            end
        end

        function outTxt = debug(obj, varargin)
            txt = util.logger.print_('D', obj, varargin);

            if nargout > 0
                outTxt = txt;
            end
        end

        function outTxt = trace(obj, varargin)
            txt = util.logger.print_('T', obj, varargin);

            if nargout > 0
                outTxt = txt;
            end
        end
    end

    methods (Access = protected, Static)
        function txt = print_(level, obj, args)
            if isa(obj, 'util.logging')
                txt = sprintf(args{:});
                obj.loggers.print(level, txt);
            else
                txt = sprintf(obj, args{:});
                loggers = util.logging.setgetLoggers();
                if ~isempty(loggers)
                    loggers.print(level, txt);
                else
                    fprintf('%c: %s\n', level, txt);
                end
            end
        end
    end
end
