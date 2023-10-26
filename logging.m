classdef logging < handle
    %LOGGING Summary of this class goes here
    %   Detailed explanation goes here

    properties
        %defaultLevel - Default log level for NEW outputs
        %   Defines the default log level applied to new outputs
        defaultLevel = 'I';
    end

    properties (SetAccess = private)
        loggers = util.logger.empty();
    end

    properties (Constant)
        defaultFormat = '[%c]: %s\n';
    end
    
    methods
        function obj = logging(varargin)
            %LOGGING Initialize the infrastructure to log messages to
            % various outputs
            %   Detailed explanation goes here
            if nargin == 0
                obj.addOutput('cmd');
            elseif nargin == 1 && isa(varargin{1}, 'util.logging')
                obj = varargin{1};
            else
                obj.addOutput(varargin{:});
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
            if isempty(id)
                id = 0;
            end

            if isgraphics(output)
                % Log to a graphic object with the field string
                logger = util.logger(id, 'gfx', output, level, format);
            elseif ischar(output) || (util.getMatlabVersion() > 2016.5 && isstring(output))
                if strcmp(output, 'cmd')
                    % Log to command window

                    % Delete logger to cmd if one exists
                    obj.loggers(strcmp({obj.loggers.type}, 'cmd')) = [];

                    % Create a new one
                    logger = util.logger(id, 'cmd', [], level, format);
                else
                    % Log to file
                    logger = util.logger(id, 'file', output, level, format);
                end
            else
                error(['Invalid log output.\nInput must be a text containing the name of the output file,' ...
                    ' for a file output, or the keyword ''cmd'' for command window output.'])
            end

            % Add logger
            obj.loggers(end+1) = logger;

            % Refresh the loggers static reference
            obj.setgetLoggers(obj.loggers);

            if nargout > 0
                outId = id;
            end
        end


        function setLogLevel(obj, level, id)
            %SETLOGLEVEL Sets the logging level
            %
            %   SETLOGLEVEL(OBJ, LEVEL) Set log level for all outputs.
            %   SETLOGLEVEL(OBJ, LEVEL, ID) Set log level for output specified by ID.
            %
            % Inputs:
            %
            %   obj     - logging object
            %   level   - Log level. It can be one of the following
            %   characters, from maximum priority to lower: 'E', 'W', 'I', 'D', 'T'
            %   id      - Identifier of the output that will be modified

            if nargin == 2
                % Assign level to all loggers
                [obj.loggers.level] = deal(level);
            else
                obj.loggers([obj.loggers.id] == id).level = level;
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
            obj.trace('Log end')
            logs = obj.setgetLoggers();
            if numel(logs) == numel(obj.loggers) && all(obj.setgetLoggers() == obj.loggers)
                obj.setgetLoggers([]);
            end
        end

        function set.defaultLevel(obj, val)
            obj.checkLevel(val);
            obj.defaultLevel = val;
        end
    end

    methods (Static)
        function num = level2Num(level)
            num = find(strcmp({'E', 'W', 'I', 'D', 'V', 'T'}, level), 1);
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

        function valid = checkLevel(level)
            if ~ischar(level)
                error('Level must be one of the following chars: ''E'', ''W'', ''I'', ''D'', ''T''.')
            end

            newVal = util.logging.level2Num(level);
            if isempty(newVal)
                error('Invalid logging level: %c\nAllowed values are ''E'', ''W'', ''I'', ''D'', ''T''.', val);
            end
            valid = true;
        end
    end

    methods (Static, Hidden)
        function pass = selfTest()
            pass = false;

            file1 = char(randi([uint8('a'), uint8('z')], 1, randi(10)));
            file2 = char(randi([uint8('a'), uint8('z')], 1, randi(10)));

            a = util.logging();
            b = util.logging('cmd');
            c = util.logging(file1);
            
            % Add second cmd output
            b.addOutput('cmd');
            b.addOutput(file2);
            b.addOutput('cmd');

            if sum(strcmp({b.loggers.type}, 'cmd')) > 1
                return
            end

            % Delete loggers
            delete(a)
            delete(b)
            delete(c)

            lastwarn('') % Clear last warning message

            % Remove files
            delete([file1 '.log'])
            delete([file2 '.log'])

            warnMsg = lastwarn;
            if ~isempty(warnMsg) % Warning has ben thrown, files couldn't be deleted
                return
            end

            pass = true;
        end
    end
end
