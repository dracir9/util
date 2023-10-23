classdef logging < handle
    %LOGGING Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = private)
        outputs
    end
    
    methods
        function obj = logging(fileName)
            %LOGGING Construct an instance of this class
            %   Detailed explanation goes here
            if isempty(fileName)
                obj = [];
                return
            end

            obj.outputs = obj.createLogger('file', fopen([fileName '.log'], 'a'), 'D');
        end

        function addOutput(obj, output)
            logger = [];
            if isgraphics(output)
                logger = obj.createLogger('gfx', output, 'I');
            elseif ischar(output)
                if strcmp(output, 'cmd')
                    logger = obj.createLogger('cmd', [], 'I');
                end
            end

            if ~isempty(logger)
                obj.outputs(end+1) = logger;
            end
        end

        function outTxt = error(obj, varargin)
            txt = sprintf(varargin{:});
            obj.print('E', txt);

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
            for ii = 1:numel(obj.outputs)
                if strcmp(obj.outputs(ii).type, 'file')
                    fclose(obj.outputs(ii).ref);
                end
            end
        end
    end

    methods (Access = protected)
        function print(obj, L, txt)
            for out = obj.outputs
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
