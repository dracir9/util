classdef FlexTab < handle
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties( Access = public, Dependent, AbortSet )
        ForegroundColor % tab text color [RGB]
        BackgroundColor % tab background color [RGB]
        HighlightColor % border highlight color [RGB]
        ShadowColor % tab border shadow color [RGB]

        BorderType % tab border type [none|line|beveledin|beveledout|etchedin|etchedout]

        TabWidth % tab width
        TabHeight % tab height

        Selection % selection

        TabEnables % tab enable states
        TabTitles % tab titles
        TabColor % tab panel color [RGB]

        FontName % font name
        FontSize % font size
        FontWeight % font weight
        FontUnits % font weight

        Position % position
    end

    properties
        SelectionChangedFcn = '' % selection change callback

        Children = matlab.graphics.Graphics.empty(0, 1) % children
    end

    properties( Access = private )
        mainPanel_ % main panel
        tabIconList_ = matlab.ui.control.UIControl.empty() % Tab icon list
        divLine_ = matlab.ui.control.UIControl.empty() % Divider line

        ForegroundColor_ = get(0, 'DefaultUitabForegroundColor') % backing for ForegroundColor
        BackgroundColor_ = get(0, 'DefaultUitabBackgroundColor') % backing for BackgroundColor
        HighlightColor_ = [1 1 1] % backing for HighlightColor
        ShadowColor_ = [0.7 0.7 0.7] % tab backing for ShadowColor
        TabColor_ = zeros(0,3) % backing for TabColor

        BorderType_ = 'none' % backing for BorderType
        TabWidth_ = [] % backing for TabWidth
        TabHeight_ = -0.1 % backing for TabHeight

        Selection_ = 1 % backing for Selection
        TabTitles_ = cell(0, 1) % backing for TabTitles
        TabEnables_ = cell(0, 1) % backing for TabEnables

        % FontAngle_ = get( 0, 'DefaultUicontrolFontAngle' ) % backing for FontAngle
        FontName_ = get(0, 'DefaultUicontrolFontName') % backing for FontName
        FontSize_ = get(0, 'DefaultUicontrolFontSize') % backing for FontSize
        FontWeight_ = get(0, 'DefaultUicontrolFontWeight') % backing for FontWeight
        FontUnits_ = get(0, 'DefaultUicontrolFontUnits') % backing for FontUnits
    end
    
    methods
        function obj = FlexTab(parent, varargin)
            %UNTITLED Construct an instance of this class
            %   Detailed explanation goes here

            % If first arg is not a graphics element attempt to use the current object or create a new figure
            if nargin > 0 && ~isa(parent, 'matlab.graphics.Graphics')
                varargin = [parent, varargin];

                parent = gco;

                if isempty(parent)
                    parent = figure();
                end
            end

            % Create parser
            p = inputParser;
            p.addParameter('ForegroundColor', obj.ForegroundColor_, @(x)validateattributes(x, {'numeric'}, ...
                {'nonnegative', 'ncols', 3, 'nrows', 1, 'ndims', 2, 'real', 'finite', '<=', 1})); % tab text color [RGB]
            p.addParameter('BackgroundColor', obj.BackgroundColor_, @(x)validateattributes(x, {'numeric'}, ...
                {'nonnegative', 'ncols', 3, 'nrows', 1, 'ndims', 2, 'real', 'finite', '<=', 1})); % tab background color [RGB]
            p.addParameter('FontName', obj.FontName_, @(x)validateattributes(x, {'char'}, {'scalartext'})); % font name
            p.addParameter('FontSize', obj.FontSize_, @(x)validateattributes(x, {'numeric'}, {'scalar', 'positive', 'real', 'finite'})); % font size
            p.addParameter('FontWeight', obj.FontWeight_, @(x)validateattributes(x, {'char'}, {'scalartext'})); % font weight
            p.addParameter('FontUnits', obj.FontUnits_, @(x)validateattributes(x, {'char'}, {'scalartext'})); % font units
            p.addParameter('BorderType', 'none', @(x)validateattributes(x, {'char'}, {'scalartext'})); % tab border type [none|line|beveledin|beveledout|etchedin|etchedout]
            p.addParameter('HighlightColor', obj.HighlightColor_, @(x)validateattributes(x, {'numeric'}, ...
                {'nonnegative', 'ncols', 3, 'nrows', 1, 'ndims', 2, 'real', 'finite', '<=', 1})); % border highlight color [RGB]
            p.addParameter('ShadowColor', obj.ShadowColor_, @(x)validateattributes(x, {'numeric'}, ...
                {'nonnegative', 'ncols', 3, 'nrows', 1, 'ndims', 2, 'real', 'finite', '<=', 1})); % border shadow color [RGB]

            % Parse name-value pairs
            p.parse(varargin{:});

            % Set properties
            obj.ForegroundColor_ = p.Results.ForegroundColor;
            obj.BackgroundColor_ = p.Results.BackgroundColor;
            obj.FontName_ = p.Results.FontName;
            obj.FontSize_ = p.Results.FontSize;
            obj.FontWeight_ = p.Results.FontWeight;
            obj.FontUnits_ = p.Results.FontUnits;
            obj.BorderType_ = p.Results.BorderType;
            obj.HighlightColor_ = p.Results.HighlightColor;
            obj.ShadowColor_ = p.Results.ShadowColor;

            try
                obj.mainPanel_ = uipanel('Parent', parent, 'BorderType', obj.BorderType_, ...
                    'HighlightColor', obj.HighlightColor_, 'Units', 'normalized', ...
                    'BackgroundColor', obj.BackgroundColor_);
            catch e
                error('FlexTab:InvalidParent', 'Invalid parent object: %s', e.message);
            end

            % Initialize layout
            obj.divLine_ = uicontrol(obj.mainPanel_, 'Style', 'text', 'BackgroundColor', 'k', ...
                'HitTest', 'off', 'HandleVisibility', 'off', 'Units', 'pixels', ...
                'Position', [0 -1 1 1]);

            % Set callbacks
            obj.mainPanel_.SizeChangedFcn = @(~, ~)obj.redrawTabs();
        end
    end

    methods
        function value = get.ForegroundColor(obj)
            value = obj.ForegroundColor_;
        end

        function set.ForegroundColor(obj, value)
            validateattributes(value, {'numeric'}, {'nonnegative', 'ncols', 3, 'nrows', 1, 'ndims', 2, 'real', 'finite', '<=', 1});

            obj.ForegroundColor_ = value;
        end

        function value = get.BackgroundColor(obj)
            value = obj.BackgroundColor_;
        end

        function set.BackgroundColor(obj, value)
            validateattributes(value, {'numeric'}, {'nonnegative', 'ncols', 3, 'nrows', 1, 'ndims', 2, 'real', 'finite', '<=', 1});

            obj.BackgroundColor_ = value;
        end

        function value = get.HighlightColor(obj)
            value = obj.HighlightColor_;
        end

        function set.HighlightColor(obj, value)
            validateattributes(value, {'numeric'}, {'nonnegative', 'ncols', 3, 'nrows', 1, 'ndims', 2, 'real', 'finite', '<=', 1});

            obj.mainPanel_.HighlightColor = value;

            obj.HighlightColor_ = value;
        end

        function value = get.ShadowColor(obj)
            value = obj.ShadowColor_;
        end

        function set.ShadowColor(obj, value)
            validateattributes(value, {'numeric'}, {'nonnegative', 'ncols', 3, 'nrows', 1, 'ndims', 2, 'real', 'finite', '<=', 1});

            obj.mainPanel_.ShadowColor = value;

            obj.ShadowColor_ = value;

            % Redraw tabs
            obj.redrawTabs()
        end

        function value = get.BorderType(obj)
            value = obj.BorderType_;
        end

        function set.BorderType(obj, value)
            validateattributes(value, {'char'}, {'scalartext'});

            obj.mainPanel_.BorderType = value;

            obj.BorderType_ = value;
        end

        function value = get.TabWidth(obj)
            value = obj.TabWidth_;
        end

        function set.TabWidth(obj, value)
            validateattributes(value, {'numeric'}, {'numel', numel(obj.Children), 'real', 'finite'});

            obj.TabWidth_ = value;

            % Redraw tabs
            obj.redrawTabs()
        end

        function value = get.TabHeight(obj)
            value = obj.TabHeight_;
        end

        function set.TabHeight(obj, value)
            validateattributes(value, {'numeric'}, {'scalar', 'real', '>=', -1, 'finite'});

            obj.TabHeight_ = value;

            % Redraw tabs
            obj.redrawTabs()
        end

        function value = get.Selection(obj)
            value = obj.Children(obj.Selection_);
        end

        function set.Selection(obj, value)
            validateattributes(value, {'matlab.graphics.Graphics'}, {'scalar'});

            [ismem, idx] = ismember(value, obj.Children);
            if ~ismem
                error('FlexTab:InvalidSelection', 'Invalid selection');
            end

            obj.switchTab(idx);

            obj.Selection_ = idx;
        end

        function value = get.TabEnables(obj)
            value = obj.TabEnables_;
        end

        function set.TabEnables(obj, value)

            % Convert
            try
                value = cellstr(value);
            catch
                error('FlexTab:InvalidPropertyValue', ...
                    'Property ''TabEnables'' must be a cell array of strings ''on'' or ''off'', one per tab.')
            end

            % Reshape
            value = value(:);

            % Check
            assert(isequal(numel(value), numel(obj.Children)) && ...
                all(ismember(value, {'on', 'off'})), ...
                'FlexTab:InvalidPropertyValue', ...
                'Property ''TabEnables'' must be a cell array of strings ''on'' or ''off'', one per tab.')

            % Set
            obj.TabEnables_ = value;

            % Redraw tabs
            obj.redrawTabs()
        end

        function value = get.TabTitles(obj)
            value = obj.TabTitles_;
        end

        function set.TabTitles(obj, value)

            % Convert
            try
                value = cellstr(value);
            catch
                error('FlexTab:InvalidPropertyValue', ...
                    'Property ''TabTitles'' must be a cell array of strings, one per tab.')
            end

            % Reshape
            value = value(:);

            % Check
            assert(isequal(numel(value), numel(obj.Children)), ...
                'FlexTab:InvalidPropertyValue', ...
                'Property ''TabTitles'' must be a cell array of strings, one per tab.')

            % Set
            for ii = 1:numel(value)
                obj.tabIconList_(ii).String = value{ii};
            end

            % Redraw tabs
            obj.redrawTabs()
        end

        function value = get.TabColor(obj)
            value = obj.TabColor_;
        end

        function set.TabColor(obj, value)
            validateattributes(value, {'numeric'}, {'nonnegative', 'ncols', 3, 'ndims', 2, 'real', 'finite', '<=', 1});

            assert(isequal(size(value, 1), numel(obj.Children)), ...
                'FlexTab:InvalidPropertyValue', ...
                'Property ''TabColor'' must be a n-by-3 matrix of RGB values, one per tab.')

            obj.TabColor_ = value;
        end

        function value = get.FontName(obj)
            value = obj.FontName_;
        end

        function set.FontName(obj, value)
            validateattributes(value, {'char'}, {'scalartext'});

            try
                for ii = 1:numel(obj.tabIconList_)
                    obj.tabIconList_(ii).FontName = value;
                end
            catch e
                throwAsCaller(e);
            end

            obj.FontName_ = value;
        end

        function value = get.FontSize(obj)
            value = obj.FontSize_;
        end

        function set.FontSize(obj, value)
            validateattributes(value, {'numeric'}, {'scalar', 'positive', 'real', 'finite'});

            try
                for ii = 1:numel(obj.tabIconList_)
                    obj.tabIconList_(ii).FontSize = value;
                end
            catch e
                throwAsCaller(e);
            end

            obj.FontSize_ = value;
        end

        function value = get.FontWeight(obj)
            value = obj.FontWeight_;
        end

        function set.FontWeight(obj, value)
            validateattributes(value, {'char'}, {'scalartext'});

            try
                for ii = 1:numel(obj.tabIconList_)
                    obj.tabIconList_(ii).FontWeight = value;
                end
            catch e
                throwAsCaller(e);
            end

            obj.FontWeight_ = value;
        end

        function value = get.FontUnits(obj)
            value = obj.FontUnits_;
        end

        function set.FontUnits(obj, value)
            validateattributes(value, {'char'}, {'scalartext'});

            try
                for ii = 1:numel(obj.tabIconList_)
                    obj.tabIconList_(ii).FontUnits = value;
                end
            catch e
                throwAsCaller(e);
            end

            obj.FontUnits_ = value;
        end

        function value = get.Position(obj)
            value = obj.mainPanel_.Position;
        end

        function set.Position(obj, value)
            validateattributes(value, {'numeric'}, {'vector', 'numel', 4, 'real', 'finite'});

            obj.mainPanel_.Position = value;
        end
    end

    methods
        function addTab(obj, title, varargin)
            % Add a tab
            %   obj.addTab(title) adds a tab with the specified title
            %   obj.addTab(title, 'PropertyName', 'PropertyValue', ...) adds a tab with the specified title and properties

            % Create parser
            p = inputParser;
            p.addRequired('title', @(x)validateattributes(x, {'char'}, {'scalartext'})); % tab title
            p.addOptional('Color', get(0, 'DefaultUitabBackgroundColor'), @(x)validateattributes(x, {'numeric'}, ...
                {'nonnegative', 'ncols', 3, 'nrows', 1, 'ndims', 2, 'real', 'finite', '<=', 1})); % tab panel color [RGB]
            p.addOptional('Width', -1, @(x)validateattributes(x, {'numeric'}, {'scalar', 'real', 'finite'})); % tab width
            p.addOptional('Enable', 'on', @(x)validateattributes(x, {'char'}, {'scalartext'})); % tab enable state

            % Parse name-value pairs
            p.parse(title, varargin{:});

            % Set properties
            title = p.Results.title;
            color = p.Results.Color;
            width = p.Results.Width;

            if strcmp(p.Results.Enable, 'on')
                enable = 'inactive';
            elseif strcmp(p.Results.Enable, 'off')
                enable = 'off';
            else
                error('FlexTab:InvalidPropertyValue', 'Property ''Enable'' must be ''on'' or ''off''')
            end

            % Create tab
            tab = uipanel('Parent', obj.mainPanel_, 'Units', 'normalized', 'BackgroundColor', color, 'Visible', 'on', ...
                'BorderType', 'none', 'HighlightColor', 'k');

            uistack(tab, 'bottom')

            % Create tab icon
            tabIcon = uicontainer('Parent', obj.mainPanel_, 'Units', 'normalized', ...
                'BackgroundColor', color, ...
                'ButtonDownFcn', @(~, ~)obj.switchTab(numel(obj.Children) + 1));

            label = uicontrol('Parent', tabIcon, 'Style', 'text', 'String', title, ...
                'BackgroundColor', color, 'ForegroundColor', obj.ForegroundColor_, 'FontName', obj.FontName_, ...
                'FontSize', obj.FontSize_, 'FontWeight', obj.FontWeight_, 'FontUnits', obj.FontUnits_, ...
                'HorizontalAlignment', 'center', 'Units', 'pixels', ...
                'Enable', enable, 'HandleVisibility', 'off', 'HitTest', 'off');

            uistack(tabIcon, 'bottom')
            
            tabIcon.SizeChangedFcn = @(~, ~)centerText(label, tabIcon);

            % Add tab to list
            obj.Children(end + 1) = tab;

            % Add tab icon to list
            obj.tabIconList_(end + 1) = tabIcon;

            % Set tab title
            obj.TabTitles_{end + 1} = title;

            % Set tab enable
            obj.TabEnables_{end + 1} = p.Results.Enable;

            % Set tab color
            obj.TabColor_(end + 1, :) = color;

            % Set tab width
            obj.TabWidth_(end + 1) = width;

            % Redraw tabs
            obj.redrawTabs()

            function centerText(txt, parent)
                bo = hgconvertunits(ancestor(parent, 'figure'), ...
                    [0 0 1 1], 'normalized', 'pixels', parent ); % bounds
                e = txt.Extent;

                x = 1 + bo(3)/2 - e(3)/2;
                w = e(3);
                y = bo(4)/2 - e(4)/2;
                h = e(4);

                txt.Position = [x y w h];
            end
        end

        function redrawTabs(obj)
            % Redraw tabs
            %   obj.redrawTabs() redraws the tabs

            % Get main panel size
            panelSz = getpixelposition(obj.mainPanel_);

            % Available width
            availWidth = panelSz(3) - sum(obj.TabWidth_(obj.TabWidth_ > 0));
            widthUnit = availWidth / sum(obj.TabWidth_(obj.TabWidth_ < 0));
            tabWidth = obj.TabWidth_;
            tabWidth(tabWidth < 0) = widthUnit*tabWidth(tabWidth < 0);
            xPos = cumsum([0 tabWidth(1:end-1)]);

            if obj.TabHeight_ < 0
                tabHeight = -panelSz(4) * obj.TabHeight_;
            else
                tabHeight = obj.TabHeight_;
            end

            tabHeight = tabHeight - 1;

            % Set divider line position
            obj.divLine_.Position = [0 panelSz(4)-tabHeight-1 panelSz(3) 1];

            % Set tab icon positions
            for ii = 1:numel(obj.tabIconList_)
                obj.tabIconList_(ii).Units = 'pixels';
                obj.tabIconList_(ii).Position = [xPos(ii) panelSz(4)-tabHeight tabWidth(ii) tabHeight];
                obj.tabIconList_(ii).Units = 'normalized';
            end

            % Set tab positions
            for ii = 1:numel(obj.Children)
                obj.Children(ii).Units = 'pixels';
                obj.Children(ii).Position(4) = panelSz(4)-tabHeight-1;
                obj.Children(ii).Units = 'normalized';
            end
        end
    end

    methods (Static)
        function selfTest()
            %SELFTEST Test the FlexTab class
            %
            %   SELFTEST() runs a test of the FlexTab class.

            fig1 = figure();

            tab1 = util.FlexTab(fig1, 'ForegroundColor', [0 0 0], 'BackgroundColor', [1 1 1], ...
                'FontName', 'Arial', 'FontSize', 12, 'FontWeight', 'bold', 'FontUnits', 'points', ...
                'BorderType', 'etchedin', 'HighlightColor', [1 1 1], 'ShadowColor', [1 1 1]);

            tab1.addTab('gTg');
            tab1.addTab('Tab 2', 'Color', [1 0 0]);
        end
    end
end

