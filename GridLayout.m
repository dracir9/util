classdef GridLayout < handle
    %GRIDLAYOUT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Parent

        Spacing = 10
        Padding = 10
    end

    properties (Access = private)
        gridAxes = gobjects(0,1)
        axListeners = event.listener.empty()

        cols = 1
        rows = 1

        oldInsets = []

        outAxID = 0
    end
    
    methods
        function gl = GridLayout(Parent, m, n, varargin)
            %GRIDLAYOUT Construct an instance of this class
            %   Detailed explanation goes here

            % If first arg is not a graphics element attempt to use the current object or create a new figure
            if ~isa(Parent, 'matlab.graphics.Graphics')
                if nargin > 2
                    varargin = [n varargin];
                end
                n = m;
                m = Parent;

                Parent = gco;

                if isempty(Parent)
                    Parent = figure();
                end
            end

            % Check input parameters
            validateattributes(m, {'numeric'}, {'scalar', 'finite', 'real', 'positive'}, 'GridLayout', 'm')
            validateattributes(n, {'numeric'}, {'scalar', 'finite', 'real', 'positive'}, 'GridLayout', 'n')

            gl.Parent = uipanel('Parent', Parent, 'BorderType', 'none', 'Units', 'normalized');
            gl.rows = m;
            gl.cols = n;

            % Create parser
            p = inputParser;
            p.addParameter('Spacing', 10, @(x)validateattributes(x, {'numeric'}, {'scalar', 'finite', 'real', 'nonnegative'}));
            p.addParameter('Padding', 10, @(x)validateattributes(x, {'numeric'}, {'scalar', 'finite', 'real', 'nonnegative'}));

            % Parse name-value pairs
            p.parse(varargin{:})

            % Set parameters
            gl.Spacing = p.Results.Spacing;
            gl.Padding = p.Results.Padding;

            gl.gridAxes = gobjects(m, n);
            gl.Parent.SizeChangedFcn = @gl.sizeChanged_Cb;
        end

        function delete(~)

        end
        
        function ax = nextCell(gl, varargin)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here

            if gl.outAxID <= gl.cols*gl.rows
                gl.outAxID = gl.outAxID + 1;
            else
                error('All cells have already been created')
            end

            ax = axes(varargin{:}, 'Parent', gl.Parent, 'Units', 'pixels', 'UserData', gl.outAxID);
            
            gl.gridAxes(gl.outAxID) = ax;

            % Initialize oldInset
            gl.oldInsets(gl.outAxID, 1:4) = ax.TightInset;

            % Adjust axes grid at least once
            gl.sizeChanged_Cb();
            
            % Create listener to auto-update axes grid
            gl.axListeners(gl.outAxID) = addlistener(ax, 'MarkedClean', @gl.axesUpdated_Cb);
        end
    end

    methods (Access = private)
        function axesUpdated_Cb(gl, src, ~)
            % Get insets in pixels
            insetList = vertcat(gl.gridAxes(1:gl.outAxID).TightInset);

            % If tightInset variable has changed, update
            if max(abs(insetList(:) - gl.oldInsets(:))) >= 1
                disp(src.UserData)
                gl.updateAxGrid(insetList);
            end
        end

        function sizeChanged_Cb(gl, ~, ~)
            % Get insets in pixels
            insetList = vertcat(gl.gridAxes(1:gl.outAxID).TightInset);

            % Update grid
            gl.updateAxGrid(insetList);
        end

        function updateAxGrid(gl, insetList)
            % Get parent position and size in pixels
            parentPos = getpixelposition(gl.Parent);

            % Get maximum size available
            maxSize = parentPos(3:4);

            % Expand missing elements
            axInset = zeros(4, gl.rows, gl.cols);

            % Diable axes events
            for ii = 1:numel(gl.axListeners)
                gl.axListeners(ii).Enabled = false;
            end
            
            for iteration = 1:10
                axInset(1:numel(insetList)) = insetList';
    
                % Calculate spacing between cells
                Xspacing = max(axInset(3, :, 1:end-1) + axInset(1, :, 2:end), gl.Spacing);
                Xspacing = max(Xspacing(:));
    
                Yspacing = max(axInset(2, 1:end-1, :) + axInset(4, 2:end, :), gl.Spacing);
                Yspacing = max(Yspacing(:));
    
                % Calculate border space arround axes
                Xinset = [max(axInset(1, :, 1)), max(axInset(3, :, end))] + gl.Padding;
                Yinset = [max(axInset(2, 1, :)), max(axInset(4, end, :))] + gl.Padding;
    
                % Calculate axes sizes
                axWidth = (maxSize(1) - Xspacing*(gl.cols-1) - sum(Xinset))/gl.cols;
                axHeight = (maxSize(2) - Yspacing*(gl.rows-1) - sum(Yinset))/gl.rows;
    
                id = 0;
                for jj = 1:gl.cols
                    for ii = 1:gl.rows
                        if id >= gl.outAxID
                            break
                        end
                        id = id+1;
                        
                        gl.gridAxes(ii, jj).Position = [...
                            Xinset(1) + axWidth*(jj-1) + Xspacing*(jj-1), ...
                            Yinset(1) + axHeight*(gl.rows-ii) + Yspacing*(gl.rows-ii), ...
                            axWidth, ...
                            axHeight];
                    end
                end
                
                gl.oldInsets = insetList;

                insetList = vertcat(gl.gridAxes(1:gl.outAxID).TightInset);
                if all(insetList(:) == gl.oldInsets(:))
                    break;
                end
            end

            % Enable axes events
            for ii = 1:numel(gl.axListeners)
                gl.axListeners(ii).Enabled = true;
            end
        end
    end

    methods (Static)
        function selfTest()
            fig = figure();

            nCol = randi(6);
            nRow = randi(6);

            gl = util.GridLayout(fig, nRow, nCol, 'Spacing', 50, 'Padding', 10);

            for ii = 1:(nCol*nRow)
                gl.nextCell();
            end
        end
    end
end

