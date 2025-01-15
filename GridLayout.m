classdef GridLayout < handle
    %GRIDLAYOUT GridLayout class to create a grid of axes
    %
    %  gl = GridLayout(Parent, m, n) creates a new GridLayout object with m rows and n columns in the specified parent object.
    %
    % GridLayout properties:
    %  R/W  Parent      - Parent object where the GridLayout will be created
    %  R/w  Spacing     - Spacing between cells in pixels
    %  R/W  Padding     - Padding around the grid in pixels
    %
    % Author: Ricard Bitriá Ribes
    % Date: December 2024

    properties (Dependent)
        Parent

        Widths
        Heights
        Spacing
        Padding
    end

    properties (SetAccess = private)
        cols = 1
        rows = 1
    end

    properties (Access = private)
        Panel
        gridAxes = gobjects(0,1)
        axListeners = event.listener.empty()

        outAxID = 0
        
        useOuterPos = false;

        % Internal properties
        Spacing_ = 10
        Padding_ = 10

        Widths_ = -1
        Heights_ = -1
    end
    
    methods
        function gl = GridLayout(Parent, m, n, varargin)
            %GRIDLAYOUT Create a new GridLayout object
            %
            %   gl = GRIDLAYOUT(Parent, m, n) creates a new GridLayout object with m rows and n columns in the specified parent object.
            %   gl = GRIDLAYOUT(Parent, m, n, Name, Value) creates a new GridLayout object with m rows and n columns in the specified parent object with the specified properties.
            %
            % Inputs:
            %   Parent      - Parent object where the GridLayout will be created
            %   m           - Number of rows
            %   n           - Number of columns
            %   varargin    - Name-Value pair arguments to set properties:
            %            > Spacing: Spacing between cells in pixels (default: 10)
            %            > Padding: Padding around the grid in pixels (default: 10)
            %
            % Outputs:
            %   gl          - GridLayout object

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

            if isprop(Parent, 'Color')
                color = Parent.Color;
            elseif isprop(Parent, 'BackgroundColor')
                color = Parent.BackgroundColor;
            end

            gl.Panel = uipanel('Parent', Parent, 'BorderType', 'none', 'Units', 'normalized', 'BackgroundColor', color);
            gl.rows = m;
            gl.cols = n;

            % Create parser
            p = inputParser;
            p.addParameter('Spacing', 10, @(x)validateattributes(x, {'numeric'}, {'scalar', 'finite', 'real', 'nonnegative'}));
            p.addParameter('Padding', 10, @(x)validateattributes(x, {'numeric'}, {'scalar', 'finite', 'real', 'nonnegative'}));
            p.addParameter('Widths', -ones(1,n), @(x)validateattributes(x, {'numeric'}, {'vector', 'numel', n, 'finite', 'real'}));
            p.addParameter('Heights', -ones(1,m), @(x)validateattributes(x, {'numeric'}, {'vector', 'numel', m, 'finite', 'real'}));

            % Parse name-value pairs
            p.parse(varargin{:})

            % Set parameters
            gl.Spacing_ = p.Results.Spacing;
            gl.Padding_ = p.Results.Padding;
            gl.Widths_ = p.Results.Widths;
            gl.Heights_ = p.Results.Heights;
            gl.outAxID = 0;

            gl.gridAxes = gobjects(m, n);
            
            if verLessThan('matlab', '9.8')
                gl.useOuterPos = true;
            else
                gl.useOuterPos = false;
            end
            
            gl.Panel.SizeChangedFcn = @gl.sizeChanged_Cb;
        end

        function delete(~)

        end
        
        function ax = nextCell(gl, varargin)
            %NEXTCELL Create a new axes in the next cell of the grid layout
            %
            %   ax = NEXTCELL(gl) creates a new axes in the next cell of the grid layout and returns the axes handle.
            %   ax = NEXTCELL(gl, Name, Value) creates a new axes in the next cell of the grid layout with the specified properties.
            %
            % Inputs:
            %   gl          - GridLayout object
            %   varargin    - Name-Value pair arguments to create axes
            %
            % Outputs:
            %   ax          - Axes handle

            if gl.outAxID <= gl.cols*gl.rows
                gl.outAxID = gl.outAxID + 1;
            else
                error('All cells have already been created')
            end

            % Create axes
            % 'LooseInset' hidden property needs to be set to 0 to properly trigger OuterPositionChanged event
            ax = axes(varargin{:}, 'Parent', gl.Panel, 'Units', 'pixels', 'LooseInset', [0 0 0 0]);
            
            gl.gridAxes(gl.outAxID) = ax;

            % Adjust axes grid at least once
            gl.sizeChanged_Cb();
            
            % Create listener to auto-update axes grid
            if verLessThan('matlab', '9.8')
                gl.axListeners(gl.outAxID) = addlistener(ax, 'SizeChanged', @gl.axesUpdated_Cb);
            else
                gl.axListeners(gl.outAxID) = addlistener(ax, 'OuterPositionChanged', @gl.axesUpdated_Cb);
            end
        end

        % Getters and setters
        function value = get.Parent(gl)
            value = gl.Panel.Parent;
        end

        function value = get.Widths(gl)
            value = gl.Widths_;
        end

        function value = get.Heights(gl)
            value = gl.Heights_;
        end

        function value = get.Spacing(gl)
            value = gl.Spacing_;
        end

        function value = get.Padding(gl)
            value = gl.Padding_;
        end

        function set.Parent(gl, value)
            validateattributes(value, {'matlab.ui.Figure', 'matlab.ui.container.Panel'}, {'scalar'}, 'GridLayout', 'Parent')
            gl.Panel.Parent = value;

            if isprop(value, 'Color')
                color = value.Color;
            elseif isprop(value, 'BackgroundColor')
                color = value.BackgroundColor;
            end

            gl.Panel.BackgroundColor = color;
        end

        function set.Widths(gl, value)
            validateattributes(value, {'numeric'}, {'vector', 'numel', gl.cols, 'finite', 'real'}, 'GridLayout', 'Widths')
            gl.Widths_ = value;
            gl.updateAxGrid();
        end

        function set.Heights(gl, value)
            validateattributes(value, {'numeric'}, {'vector', 'numel', gl.rows, 'finite', 'real'}, 'GridLayout', 'Heights')
            gl.Heights_ = value;
            gl.updateAxGrid();
        end

        function set.Spacing(gl, value)
            validateattributes(value, {'numeric'}, {'scalar', 'finite', 'real', 'nonnegative'}, 'GridLayout', 'Spacing')
            gl.Spacing_ = value;
            gl.updateAxGrid();
        end

        function set.Padding(gl, value)
            validateattributes(value, {'numeric'}, {'scalar', 'finite', 'real', 'nonnegative'}, 'GridLayout', 'Padding')
            gl.Padding_ = value;
            gl.updateAxGrid();
        end
    end

    methods (Access = private)
        function axesUpdated_Cb(gl, ~, ~)
            gl.updateAxGrid();
        end

        function sizeChanged_Cb(gl, ~, ~)
            if gl.outAxID == 0
                return
            end

            % Update grid
            gl.updateAxGrid();
        end

        function updateAxGrid(gl)
            % Get insets in pixels
            insetList = vertcat(gl.gridAxes(1:gl.outAxID).TightInset);

            % Get parent position and size in pixels
            parentPos = getpixelposition(gl.Panel);

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
                if gl.cols > 1
                    Xspacing = axInset(3, :, 1:end-1) + axInset(1, :, 2:end);
                    Xspacing = max(Xspacing(:)) + gl.Spacing_;
                else
                    Xspacing = 0;
                end
    
                if gl.rows > 1
                    Yspacing = axInset(2, 1:end-1, :) + axInset(4, 2:end, :);
                    Yspacing = max(Yspacing(:)) + gl.Spacing_;
                else
                    Yspacing = 0;
                end
    
                % Calculate border space arround axes
                Xinset = [max(axInset(1, :, 1)), max(axInset(3, :, end))] + gl.Padding_;
                Yinset = [max(axInset(2, end, :)), max(axInset(4, 1, :))] + gl.Padding_;
    
                % Calculate axes sizes
                fixedWidth = sum(gl.Widths_(gl.Widths_ > 0));
                widthWeight = -sum(gl.Widths_(gl.Widths_ < 0));
                fixedHeight = sum(gl.Heights_(gl.Heights_ > 0));
                heightWeight = -sum(gl.Heights_(gl.Heights_ < 0));
                
                % Calculate width and height per wheigth unit
                minXunit = max((maxSize(1) - Xspacing*(gl.cols-1) - sum(Xinset) - fixedWidth)/widthWeight, 0);
                minYunit = max((maxSize(2) - Yspacing*(gl.rows-1) - sum(Yinset) - fixedHeight)/heightWeight, 0);
                
                axWidth = gl.Widths_;
                axWidth(axWidth < 0) = -axWidth(axWidth < 0)*minXunit;
                Xoffset = cumsum([0 axWidth]);
                axHeight = gl.Heights_;
                axHeight(axHeight < 0) = -axHeight(axHeight < 0)*minYunit;
                Yoffset = fliplr([0 cumsum(fliplr(axHeight(2:end)))]);
    
                id = 0;
                for jj = 1:gl.cols
                    for ii = 1:gl.rows
                        if id >= gl.outAxID
                            break
                        end
                        id = id+1;
                        
                        gl.gridAxes(ii, jj).Position = [...
                            Xinset(1) + Xoffset(jj) + Xspacing*(jj-1), ...
                            Yinset(1) + Yoffset(ii) + Yspacing*(gl.rows-ii), ...
                            axWidth(jj), ...
                            axHeight(ii)];
                        
                        if gl.useOuterPos
                            gl.gridAxes(ii, jj).ActivePositionProperty = 'outerPosition';
                        end
                    end
                end
                
                oldInsets = insetList;

                insetList = vertcat(gl.gridAxes(1:gl.outAxID).TightInset);
                if all(insetList(:) == oldInsets(:))
                    break;
                end
            end

            if iteration == 10
                % Force redraw before enabling the listeners
                drawnow
            end

            % Enable axes events
            for ii = 1:numel(gl.axListeners)
                gl.axListeners(ii).Enabled = true;
            end
        end
    end

    methods (Static)
        function selfTest()
            %SELFTEST Test the GridLayout class
            %
            %   SELFTEST() runs a test of the GridLayout class.

            fig1 = figure();

            gl = util.GridLayout(fig1, 1, 1, 'Spacing', 50, 'Padding', 10);
            gl.nextCell();

            fig2 = figure();
            gl = util.GridLayout(fig2, 1, 3, 'Spacing', 50, 'Padding', 10);
            gl.nextCell();
            gl.nextCell();
            gl.nextCell();
            gl.Widths = [100, -1, -2];

            fig3 = figure();
            gl = util.GridLayout(fig3, 3, 1, 'Spacing', 8, 'Padding', 8);
            gl.nextCell();
            gl.nextCell();
            gl.nextCell();
            gl.Heights = [-1, 100, -2];

            fig4 = figure();
            gl = util.GridLayout(fig4, 3, 3, 'Spacing', 50, 'Padding', 10);
            gl.nextCell();
            gl.nextCell();
            gl.nextCell();
            gl.nextCell();
            gl.nextCell();
            gl.nextCell();
            gl.nextCell();
            gl.nextCell();
            gl.nextCell();

            nCol = 3+randi(3);
            nRow = 3+randi(3);

            fig5 = figure('Color', 'w');
            gl = util.GridLayout(fig5, nCol, nRow, 'Spacing', 0, 'Padding', 0);

            for ii = 1:(nCol*nRow)
                gl.nextCell();
            end

            gl.Spacing = 10;
            gl.Padding = 20;

            p = uipanel('Parent', fig5, 'Units', 'normalized', 'Position', [0.5 0 0.5 1], 'BackgroundColor', 'r');
            gl.Parent = p;
        end
    end
end

