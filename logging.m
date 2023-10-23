classdef logging < handle
    %LOGGING Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess = private)
        loggers
    end

    properties (Constant)
        defaultFormat = '[%c]: %s';
        defaultLevel = 'I';
    end
    
    methods
        function obj = logging()
            %LOGGING Construct an instance of this class
            %   Detailed explanation goes here

            obj.loggers = util.logger(0, 'cmd', [], 'I', '[%c]: %s');
            obj.setgetLoggers(obj.loggers);
        end

        function outId = addOutput(obj, output, level, format)
            if nargin < 4
                format = obj.defaultFormat;
            end
            
            if nargin < 3
                level = obj.defaultLevel;
            end

            id = max([obj.loggers.id])+1;

            if isgraphics(output)
                logger = util.logger(id, 'gfx', output, level, format);
            elseif ischar(output)
                if strcmp(output, 'cmd')
                    cmdExists = false;
                    for ii = 1:numel(obj.loggers)
                        if strcmp(obj.loggers(ii).type, 'cmd')
                            obj.loggers(ii) = util.logger(id, 'cmd', [], level, format);
                            cmdExists = true;
                        end
                    end

                    if ~cmdExists
                        logger = util.logger(id, 'cmd', [], level, format);
                    else
                        logger = [];
                    end
                else
                    logger = util.logger(id, 'file', output, level, format);
                end
            end

            if ~isempty(logger)
                obj.loggers(end+1) = logger;
            end
            obj.setgetLoggers(obj.loggers);

            if nargout > 0
                outId = id;
            end
        end

        function outTxt = error(obj, varargin)
            txt = sprintf(varargin{:});
            
            obj.loggers.print('E', txt);

            if nargout > 0
                outTxt = txt;
            end
        end

        function outTxt = warning(obj, varargin)
            txt = sprintf(varargin{:});
            
            obj.loggers.print('W', txt);

            if nargout > 0
                outTxt = txt;
            end
        end

        function outTxt = info(obj, varargin)
            txt = sprintf(varargin{:});
            
            obj.loggers.print('I', txt);

            if nargout > 0
                outTxt = txt;
            end
        end

        function outTxt = debug(obj, varargin)
            txt = sprintf(varargin{:});
            
            obj.loggers.print('D', txt);

            if nargout > 0
                outTxt = txt;
            end
        end

        function outTxt = trace(obj, varargin)
            txt = sprintf(varargin{:});
            
            obj.loggers.print('T', txt);

            if nargout > 0
                outTxt = txt;
            end
        end

        function delete(obj)
            disp('Log disabled')
            
            logs = obj.setgetLoggers();
            if numel(logs) == numel(obj.loggers) && all(obj.setgetLoggers() == obj.loggers)
                obj.setgetLoggers([]);
            end
        end
    end

    methods (Access = ?util.logger, Static)
        function h = setgetLoggers(obj)
            persistent logHandle;
            if nargin
                logHandle = obj;
            end
            h = logHandle;
        end
    end
end
