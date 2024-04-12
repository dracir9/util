classdef modulardlg < handle
    %PROMPTDLG Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        fig     matlab.ui.Figure

        padding = 5;
        margin = [5, 5, 5, 5];
        controlWidth = 125;
        controlHeight = 18;

        fontsize
        bgcolor
    end

    properties (Dependent)
        Position
    end

    properties (Dependent, SetAccess = private)
        totalWidth;
        totalHeight;
    end

    properties (Access = private)
        rootElems = [];
        elems = struct('hdle', gobjects(0), 'var', '', 'type', '', 'weight', -1, 'size', [], 'Children', [], 'Parent', []);

        activeElement = 0;
    end

    properties (Constant, Access = private)
        minWidth = 200;
        minHeight = 20;
    end
    
    methods
        function dlg = modulardlg(varargin)
            %PROMPTDLG Construct an instance of this class
            %   Detailed explanation goes here

            % Delete all elements
            dlg.elems(:) = [];

            figPos = [];
            if nargin > 0
                if isgraphics(varargin{1}, 'figure')
                    figPos = varargin{1}.Position;
                elseif isnumeric(varargin{1}) && numel(varargin{1}, 2)
                    figPos = varargin{1};
                end
            end

            % get screensize and determine proper figure position
            if isempty(dlg.fig)
                scz = get(0, 'ScreenSize');               % put the window in the center of the screen
                scx = round(scz(3)/2 - dlg.minWidth/2);    % (this will usually work fine, except on some  
                scy = round(scz(4)/2 - dlg.minHeight/2);    % multi-monitor setups)   
            else
                scx = round(figPos(1) - dlg.minWidth/2);
                scy = round(figPos(2) - dlg.minHeight/2);
            end

            dlg.fig = figure(...
             'position'        , [scx, scy, dlg.minWidth, dlg.minHeight],...% figure position
             'visible'         , 'off',...         % Hide the dialog while in construction
             'backingstore'    , 'off',...         % DON'T save a copy in the background         
             'resize'          , 'off', ...        % disable resizing
             'units'           , 'pixels',...
             'DockControls'    , 'off',...         % force it to be non-dockable
             'name'            , 'Settings',...    % dialog title
             'menubar'         , 'none', ...       % no menubar
             'toolbar'         , 'none', ...       % no toolbar
             'NumberTitle'     , 'off',...
             'UserData'        , 'r',...
             'CloseRequestFcn' , @(src, evt)close_Cb(dlg, src));% Close callback

            dlg.Position = [scx, scy, dlg.minWidth, dlg.minHeight];

            dlg.bgcolor = get(0, 'defaultUicontrolBackgroundColor');
            dlg.fontsize = get(0, 'defaultuicontrolfontsize');

            dlg.controlWidth = 125;
            dlg.controlHeight = max(18, (dlg.fontsize+6));
        end

        function show(dlg)
            dlg.fig.Visible = 'on';
            waitfor(dlg.fig, 'UserData', 's');
            delete(dlg.fig)
        end

        function outId = addButton(dlg, txt, cb)
            id = dlg.registerElement('Button');

            dlg.elems(id).hdle = uicontrol(...
                'style'   , 'pushbutton',...
                'parent'  , dlg.fig,...
                'string'  , txt,...
                'position', [dlg.margin(1),dlg.margin(2), dlg.controlWidth/2.5, dlg.controlHeight*1.5],...
                'FontSize', dlg.fontsize,...
                'Callback', @(src, evt)cb(dlg, src, evt));

            dlg.draw()

            if nargout > 0
                outId = id;
            end
        end

        function outId = addEdit(dlg, txt, varName)
            id = dlg.registerElement('Edit');

            dlg.elems(id).hdle = uicontrol(...
                'style'   , 'edit',...
                'parent'  , dlg.fig,...
                'string'  , txt,...
                'position', [dlg.margin(1),dlg.margin(2), dlg.controlWidth, dlg.controlHeight],...
                'FontSize', dlg.fontsize);

            dlg.elems(id).var = varName;

            dlg.draw()

            if nargout > 0
                outId = id;
            end
        end

        function outId = addHBox(dlg)
            id = dlg.registerElement('HBox');

            % Set as the active element
            dlg.activeElement = id;

            dlg.draw()

            if nargout > 0
                outId = id;
            end
        end

        function endBox(dlg)
            dlg.activeElement = dlg.elems(dlg.activeElement).Parent;
        end

        %% Setters
        function set.Position(dlg, val)
            dlg.fig.Position = val;
        end

        %% Getters
        function val = get.Position(dlg)
            val = dlg.fig.Position;
        end

        function val = get.totalWidth(dlg)
            val = dlg.Position(3);
        end

        function val = get.totalHeight(dlg)
            val = dlg.Position(4);
        end
    end

    methods (Access = private)
        function id = registerElement(dlg, type)
            dlg.elems(end+1).type = type;
            id = numel(dlg.elems);

            % Assign parent
            dlg.elems(id).Parent = dlg.activeElement;

            % Assign children
            if dlg.activeElement == 0
                dlg.rootElems = id;
            else
                dlg.elems(dlg.activeElement).Children(end+1) = id;
            end
        end

        function getElemSize(dlg)

        end

        function draw(dlg)
            height = 0;
            width = 0;

            % Elements height
            for elem = dlg.elems
                if ~isempty(elem.hdle)
                    height = height + elem.hdle.Position(4);
                end
            end

            % Add margins
            height = height + dlg.margin(2) + dlg.margin(4);

            % Add padding
            if ~isempty(dlg.elems)
                height = height + dlg.padding*(numel(dlg.elems)-1);
            end

            % Elements width
            for elem = dlg.elems
                width = max(width, elem.hdle.Position(3));
            end

            % Add margins
            width = width + dlg.margin(1) + dlg.margin(3);

            dlg.Position(3) = max(width, dlg.minWidth);
            dlg.Position(4) = max(height, dlg.minHeight);

            % Adjust element position
            for elem = dlg.elems
                elem.hdle.Position(1) = (dlg.totalWidth - dlg.margin(1) - dlg.margin(3))/2 - elem.hdle.Position(3)/2;
            end

            Ypos = dlg.margin(2);
            for elem = dlg.elems
                elem.hdle.Position(2) = Ypos;
                Ypos = Ypos + elem.hdle.Position(4) + dlg.padding;
            end
        end

        function close_Cb(dlg, ~)
            dlg.fig.UserData = 's';
        end
    end

    methods (Static, Hidden)
        function selfTest()
            dlg = util.modulardlg();
            dlg.addButton('Hey!', @(varargin)pause(0));
            dlg.addEdit('Def', 'myvar');
            dlg.addHBox();
            dlg.addButton('Hey!', @(varargin)pause(0))
            dlg.show()
        end
    end
end

