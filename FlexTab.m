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

        ForegroundColor_ = get(0, 'DefaultUitabForegroundColor') % backing for ForegroundColor
        BackgroundColor_ = get(0, 'DefaultUitabBackgroundColor') % backing for BackgroundColor
        HighlightColor_ = [1 1 1] % backing for HighlightColor
        ShadowColor_ = [0.7 0.7 0.7] % tab backing for ShadowColor
        TabColor_ = zeros(0,3) % backing for TabColor

        BorderType_ = 'none' % backing for BorderType
        TabWidth_ = [] % backing for TabWidth
        TabHeight_ = 35 % backing for TabHeight

        Selection_ = 1 % backing for Selection
        TabTitles_ = cell(0, 1) % backing for TabTitles
        TabEnables_ = cell(0, 1) % backing for TabEnables

        % FontAngle_ = get( 0, 'DefaultUicontrolFontAngle' ) % backing for FontAngle
        FontName_ = get(0, 'DefaultUicontrolFontName') % backing for FontName
        FontSize_ = get(0, 'DefaultUicontrolFontSize')*1.2 % backing for FontSize
        FontWeight_ = 'bold' % backing for FontWeight
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
            p.addParameter('TabHeight', obj.TabHeight_, @(x)validateattributes(x, {'numeric'}, {'scalar', 'real', '>=', -1, 'finite'})); % tab height

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
            obj.TabHeight_ = p.Results.TabHeight;

            try
                obj.mainPanel_ = uipanel('Parent', parent, 'BorderType', obj.BorderType_, ...
                    'HighlightColor', obj.HighlightColor_, 'Units', 'normalized', ...
                    'BackgroundColor', obj.BackgroundColor_);
            catch e
                error('FlexTab:InvalidParent', 'Invalid parent object: %s', e.message);
            end

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

            assert(size(value, 1) <= numel(obj.Children) && size(value, 1) > 0, ...
                'FlexTab:InvalidPropertyValue', ...
                'Property ''TabColor'' must be a matrix of size 1-by-3 or N-by-3, where N is the number of tabs.')

            % Fill missing colors with the last color
            if size(value, 1) < numel(obj.Children)
                value = [value; repmat(value(end, :), numel(obj.Children) - size(value, 1), 1)];
            end

            obj.TabColor_ = value;

            obj.redrawTabs();
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

        function set.SelectionChangedFcn(obj, value)
            % Check
            if ischar(value) || isa(value, 'string') % string
                % OK
            elseif isa(value, 'function_handle') && ...
                    isscalar(value) % function handle
                % OK
            elseif iscell(value) && ndims(value) == 2 && ...
                    size(value, 1) == 1 && size(value, 2) > 0 && ...
                    isa(value{1}, 'function_handle' ) && ...
                    isscalar(value{1}) %#ok<ISMAT> % cell callback
                % OK
            else
                error('FlexTab:InvalidPropertyValue', ...
                    'Property ''SelectionChangedFcn'' must be a valid callback.')
            end

            % Set
            obj.SelectionChangedFcn = value;
        end
    end

    methods
        function tab = addTab(obj, title, varargin)
            % Add a tab
            %   obj.addTab(title) adds a tab with the specified title
            %   obj.addTab(title, 'PropertyName', 'PropertyValue', ...) adds a tab with the specified title and properties

            % Create parser
            p = inputParser;
            p.addRequired('title', @(x)validateattributes(x, {'char'}, {'scalartext'})); % tab title
            p.addParameter('Color', get(0, 'DefaultUitabBackgroundColor'), @(x)validateattributes(x, {'numeric'}, ...
                {'nonnegative', 'ncols', 3, 'nrows', 1, 'ndims', 2, 'real', 'finite', '<=', 1})); % tab panel color [RGB]
            p.addParameter('Width', -1, @(x)validateattributes(x, {'numeric'}, {'scalar', 'real', 'finite'})); % tab width
            p.addParameter('Enable', 'on', @(x)validateattributes(x, {'char'}, {'scalartext'})); % tab enable state

            % Parse name-value pairs
            p.parse(title, varargin{:});

            % Set properties
            title = p.Results.title;
            color = p.Results.Color;
            width = p.Results.Width;

            if ~strcmp(p.Results.Enable, 'on') && ~strcmp(p.Results.Enable, 'off')
                error('FlexTab:InvalidPropertyValue', 'Property ''Enable'' must be ''on'' or ''off''')
            end

            tabIdx = numel(obj.Children) + 1;

            % Create tab
            tab = uipanel('Parent', obj.mainPanel_, 'Units', 'normalized', 'BackgroundColor', color, 'Visible', 'on', ...
                'BorderType', 'beveledin', 'HighlightColor', obj.HighlightColor_);

            % Create tab icon
            tabIcon = uicontrol('Parent', obj.mainPanel_, 'Style', 'pushbutton', 'String', title, ...
                'BackgroundColor', color, 'ForegroundColor', obj.ForegroundColor_, 'FontName', obj.FontName_, ...
                'FontSize', obj.FontSize_, 'FontWeight', obj.FontWeight_, 'FontUnits', obj.FontUnits_, ...
                'HorizontalAlignment', 'center', 'Units', 'normalized', ...
                'Enable', 'inactive', 'ButtonDownFcn', @(~, ~)obj.switchTab(tabIdx));

            uistack(tabIcon, 'bottom')

            % Add tab to list
            obj.Children(tabIdx) = tab;

            % Add tab icon to list
            obj.tabIconList_(tabIdx) = tabIcon;

            % Set tab title
            obj.TabTitles_{tabIdx} = title;

            % Set tab enable
            obj.TabEnables_{tabIdx} = p.Results.Enable;

            % Set tab color
            obj.TabColor_(tabIdx, :) = color;

            % Set tab width
            obj.TabWidth_(tabIdx) = width;

            % Redraw tabs
            obj.redrawTabs();

            obj.switchTab(tabIdx);
        end

        function redrawTabs(obj)
            % Redraw tabs
            %   obj.redrawTabs() redraws the tabs

            % Get main panel size
            panelSz = hgconvertunits(ancestor(obj.mainPanel_, 'figure'), ...
                    [0 0 1 1], 'normalized', 'pixels', obj.mainPanel_); % bounds

            % Available width
            availWidth = panelSz(3) - sum(obj.TabWidth_(obj.TabWidth_ > 0));
            widthUnit = availWidth / sum(obj.TabWidth_(obj.TabWidth_ < 0));
            iconWidth = obj.TabWidth_;
            iconWidth(iconWidth < 0) = widthUnit*iconWidth(iconWidth < 0);
            xPos = cumsum([1 iconWidth(1:end-1)]);

            availHeight = panelSz(4) - sum(obj.TabHeight_(obj.TabHeight > 0));
            heightUnit = -availHeight; % / sum(obj.TabHeight_(obj.TabHeight < 0));
            iconHeight = ones(size(obj.Children)) * obj.TabHeight_;
            iconHeight(iconHeight < 0) = heightUnit*iconHeight(iconHeight < 0);
            tabHeight = panelSz(4) - iconHeight(1);
            yPos = tabHeight - 0;
            iconHeight = iconHeight + 1;

            % Add a little padding around the not-selected tabs
            padding = 6;
            iconWidth(1:end ~= obj.Selection_) = iconWidth(1:end ~= obj.Selection_) - padding;
            iconHeight(1:end ~= obj.Selection_) = iconHeight(1:end ~= obj.Selection_) - padding;
            xPos(1:end ~= obj.Selection_) = xPos(1:end ~= obj.Selection_) + padding/2;

            % Set tab positions
            for ii = 1:numel(obj.Children)
                obj.Children(ii).Units = 'pixels';
                obj.Children(ii).Position(4) = tabHeight;
                obj.Children(ii).Units = 'normalized';

                if ii == obj.Selection_
                    uistack(obj.Children(ii), 'top')
                end
            end

            % Set tab icon positions
            for ii = 1:numel(obj.tabIconList_)
                obj.tabIconList_(ii).Units = 'pixels';
                sz = [xPos(ii) yPos iconWidth(ii) iconHeight(ii)];
                obj.tabIconList_(ii).Position = sz;
                obj.tabIconList_(ii).Units = 'normalized';

                % Create tab icon image
                Isz = floor(sz(3:4));
                Idat = permute(repmat(obj.TabColor_(ii, :), Isz(2), 1, Isz(1)),[1,3,2]);

                % Add border
                Idat(1,:,:) = permute(repmat(obj.ShadowColor_, 1, 1, Isz(1)),[1,3,2]);
                Idat(:,[1,end],:) = permute(repmat(obj.ShadowColor_, Isz(2), 1, 2),[1,3,2]);
                
                obj.tabIconList_(ii).CData = Idat;

                if ii == obj.Selection_
                    uistack(obj.tabIconList_(ii), 'top')
                end
            end
        end

        function switchTab(obj, idx)
            % Switch tab
            %   obj.switchTab(idx) switches to the tab at the specified index

            % Set tab visibility
            for ii = 1:numel(obj.Children)
                if ii == idx
                    obj.Children(ii).Visible = 'on';
                else
                    obj.Children(ii).Visible = 'off';
                end
            end

            % Set tab callback
            for ii = 1:numel(obj.tabIconList_)
                if ii == idx
                    obj.tabIconList_(ii).ButtonDownFcn = '';
                else
                    obj.tabIconList_(ii).ButtonDownFcn = @(~, ~)obj.switchTab(ii);
                end
            end

            % Set selection
            obj.Selection_ = idx;

            obj.redrawTabs();

            % Call selection change callback
            callback = obj.SelectionChangedFcn;
            if ischar(callback) && isequal(callback, '')
                % do nothing
            elseif ischar(callback)
                feval(callback, source, eventData)
            elseif isa(callback, 'function_handle')
                callback(source, eventData)
            elseif iscell(callback)
                feval(callback{1}, source, eventData, callback{2:end})
            end
        end
    end

    methods (Static)
        function tb = selfTest()
            %SELFTEST Test the FlexTab class
            %
            %   SELFTEST() runs a test of the FlexTab class.

            fig1 = figure();

            tab1 = util.FlexTab(fig1);

            tab1.addTab('gTg', 'Width', 100);
            tab1.addTab('Tab 2', 'Width', -1, 'Color', [0.94 0.94 0.94]);
            tab1.addTab('Hey');

            if nargout > 0
                tb = tab1;
            end
        end
    end
end

