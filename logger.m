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

            if isempty(util.logger.level2Num(level))
                error('Invalid logging level: %s\nAllowed values are ''E'', ''W'', ''I'', ''D'', ''T''', level);
            end

            obj.id = id;
            obj.type = type;
            obj.handle = hdle;
            obj.level = level;
            obj.format = format;
        end

        function print(obj, L, txt)
            for log = obj
                if log.level2Num(L) <= log.level2Num(log.level)
                    txtFormated = sprintf(log.format, L, txt);
                    switch log.type
                        case 'cmd'
                            disp(txtFormated);
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
            disp('Delete logger')
            if strcmp(obj.type, 'file')
                fclose(obj.handle);
            end
        end
    end
    
    % methods (Static)
    %     function outTxt = error(obj, varargin)
    %         txt = sprintf(varargin{:});
    %         obj.print('E', txt);
    % 
    %         if nargout > 0
    %             outTxt = txt;
    %         end
    %     end
    % 
    %     function outTxt = warning(obj, varargin)
    %         txt = sprintf(varargin{:});
    %         obj.print('W', txt);
    % 
    %         if nargout > 0
    %             outTxt = txt;
    %         end
    %     end
    % 
    %     function outTxt = info(obj, varargin)
    %         txt = sprintf(varargin{:});
    %         obj.print('I', txt);
    % 
    %         if nargout > 0
    %             outTxt = txt;
    %         end
    %     end
    % 
    %     function outTxt = debug(obj, varargin)
    %         txt = sprintf(varargin{:});
    %         obj.print('D', txt);
    % 
    %         if nargout > 0
    %             outTxt = txt;
    %         end
    %     end
    % 
    %     function outTxt = trace(obj, varargin)
    %         txt = sprintf(varargin{:});
    %         obj.print('T', txt);
    % 
    %         if nargout > 0
    %             outTxt = txt;
    %         end
    %     end
    % 
    %     function delete(obj)
    %         disp('Bye')
    %         for ii = 1:numel(obj.output)
    %             if strcmp(obj.output(ii).type, 'file')
    %                 fclose(obj.output(ii).ref);
    %             end
    %         end
    %     end
    % end

    methods (Access = protected, Static)
        function num = level2Num(level)
            num = find(strcmp({'E', 'W', 'I', 'D', 'V', 'T'}, level), 1);
        end
    end
end
