classdef logging < handle
    %LOGGING Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess = private)
        loggers
    end

    properties (Constant)
        defaultFormat = '[%c]: %s\n';
        defaultLevel = 'T';
    end
    
    methods
        function obj = logging(varargin)
            %LOGGING Construct an instance of this class
            %   Detailed explanation goes here
            if nargin == 0
                obj.loggers = util.logger(0, 'cmd', [], obj.defaultLevel, obj.defaultFormat);
            elseif nargin == 1
                if isa(varargin{1}, 'util.logging')
                    obj = varargin{1};
                else
                    if ischar(varargin{1}) || (util.getMatlabVersion() > 2016.5 && isstring(varargin{1}))
                        if strcmp(varargin{1}, 'cmd')
                            obj.loggers = util.logger(0, 'cmd', [], obj.defaultLevel, obj.defaultFormat);
                        else
                            obj.loggers = util.logger(0, 'file', varargin{1}, obj.defaultLevel, obj.defaultFormat);
                        end
                    else
                        error(['Input must be a text containing the name of the output file,' ...
                            ' for a file output, or the keyword ''cmd'' for command window output.'])
                    end
                end
            end
            
            obj.setgetLoggers(obj.loggers);
        end

        function outId = addOutput(obj, output, level, format)
            if nargin < 4
                format = obj.defaultFormat;
            end
            
            if nargin < 3
                level = obj.defaultLevel;
            end

            % Generate a new unique ID
            id = max([obj.loggers.id])+1;

            if isgraphics(output)
                if isfield(output, 'String')
                    % Log to a graphic object with the field string
                    logger = util.logger(id, 'gfx', output, level, format);
                else
                    error('Graphic objects of type %s cannot be used for logging', output.Type)
                end
            elseif ischar(output)
                if strcmp(output, 'cmd')
                    % Log to command window
                    cmdExists = false;
                    for ii = 1:numel(obj.loggers)
                        if strcmp(obj.loggers(ii).type, 'cmd')
                            % If there is a logger connected to the command
                            % window, just update it
                            obj.loggers(ii) = util.logger(id, 'cmd', [], level, format);
                            cmdExists = true;
                            break;
                        end
                    end

                    if ~cmdExists
                        logger = util.logger(id, 'cmd', [], level, format);
                    else
                        % A logger to the command window already exists
                        logger = [];
                    end
                else
                    % Log to file
                    logger = util.logger(id, 'file', output, level, format);
                end
            end

            if ~isempty(logger)
                obj.loggers(end+1) = logger;
            end
            % Refresh the loggers static reference
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
