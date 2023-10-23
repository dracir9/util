classdef logging < handle
    %LOGGING Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = private)
        loggers
    end
    
    methods
        function obj = logging(handle)
            %LOGGING Construct an instance of this class
            %   Detailed explanation goes here

            obj.loggers = util.logger();
            obj.setgetLoggers(obj.loggers);
        end

        function addOutput(obj, output)
            if isgraphics(output)
                logger = util.logger('gfx', output, 'I');
            elseif ischar(output)
                if strcmp(output, 'cmd')
                    logger = util.logger('gfx', output, 'I');
                end
            end

            if ~isempty(logger)
                obj.loggers(end+1) = logger;
            end
        end

        function outTxt = error(obj, varargin)
            txt = sprintf(varargin{:});
            
            for log = obj.loggers
                log.print('E', txt);
            end

            if nargout > 0
                outTxt = txt;
            end
        end

        function outTxt = warning(obj, varargin)
            txt = sprintf(varargin{:});
            obj.print('W', txt);

            if nargout > 0
                outTxt = txt;
            end
        end

        function outTxt = info(obj, varargin)
            txt = sprintf(varargin{:});
            obj.print('I', txt);

            if nargout > 0
                outTxt = txt;
            end
        end

        function outTxt = debug(obj, varargin)
            txt = sprintf(varargin{:});
            obj.print('D', txt);

            if nargout > 0
                outTxt = txt;
            end
        end

        function outTxt = trace(obj, varargin)
            txt = sprintf(varargin{:});
            obj.print('T', txt);

            if nargout > 0
                outTxt = txt;
            end
        end

        function delete(obj)
            disp('Bye')
            for ii = 1:numel(obj.loggers)
                if strcmp(obj.loggers(ii).type, 'file')
                    fclose(obj.loggers(ii).ref);
                end
            end
        end
    end

    methods (Access = protected)
        function print(obj, L, txt)
            for out = obj.loggers
                if obj.level2Num(L) <= obj.level2Num(out.level)
                    txtFormated = sprintf(out.format, L, txt);
                    switch out.type
                        case 'cmd'
                            disp(txtFormated);
                        case 'file'
                            fprintf(out.ref, txtFormated);
                        case 'gfx'
                            out.ref.String = txtFormated;
                    end
                end
            end
        end
    end

    methods (Access = protected, Static)
        function h = setgetLoggers(obj)
            persistent logHandle;
            if nargin
                logHandle = obj;
            end
            h = logHandle;
        end

        function logger = createLogger(T, R, L)
            if isempty(util.logging.level2Num(L))
                error('Invalid logging level: %s\nAllowed values are ''E'', ''W'', ''I'', ''D'', ''T''', L);
            end

            logger = struct('type', T, 'ref', R, 'level', L, 'format', '[%c]: %s');
        end

        function num = level2Num(level)
            num = find(strcmp({'E', 'W', 'I', 'D', 'V', 'T'}, level), 1);
        end
    end
end
