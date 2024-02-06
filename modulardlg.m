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

    properties (SetAccess = private)
        totalWidth = 10;
        totalHeight = 10;
    end

    properties (Access = private)
        elems = gobjects(0);
        
    end
    
    methods
        function dlg = modulardlg(varargin)
            %PROMPTDLG Construct an instance of this class
            %   Detailed explanation goes here

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
                scx = round(scz(3)/2 - dlg.totalWidth/2);    % (this will usually work fine, except on some  
                scy = round(scz(4)/2 - dlg.totalHeight/2);    % multi-monitor setups)   
            else
                scx = round(figPos(1) - dlg.totalWidth/2);
                scy = round(figPos(2) - dlg.totalHeight/2);
            end

            dlg.fig = figure(...
             'position'        , [scx, scy, dlg.totalWidth, dlg.totalHeight],...% figure position
             'visible'         , 'off',...         % Hide the dialog while in construction
             'backingstore'    , 'off',...         % DON'T save a copy in the background         
             'resize'          , 'off', ...        % but just keep it resizable
             'units'           , 'pixels',...      % better for drawing
             'DockControls'    , 'off',...         % force it to be non-dockable
             'name'            , 'Settings',...         % dialog title
             'menubar'         , 'none', ...       % no menubar
             'toolbar'         , 'none', ...       % no toolbar
             'NumberTitle'     , 'off',...
             'UserData'        , 'r',...
             'CloseRequestFcn' , @(src, evt)close_Cb(dlg, src));% Close callback

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

        function id = addButton(dlg, txt, cb)
            dlg.elems(end+1) = uicontrol(...
                'style'   , 'pushbutton',...
                'parent'  , dlg.fig,...
                'string'  , txt,...
                'position', [dlg.margin(1),dlg.margin(2), dlg.controlWidth/2.5, dlg.controlHeight*1.5],...
                'FontSize', dlg.fontsize,...
                'Callback', @(src, evt)cb(dlg, src, evt));

            dlg.draw()

            if nargout > 0
                id = numel(dlg.elems);
            end
        end
    end

    methods (Access = private)
        function draw(dlg)
            height = 0;

            % Elements height
            for elem = dlg.elems
                height = height + elem.Position(4);
            end

            % Add margins
            height = height + dlg.margin(2) + dlg.margin(4);

            % Add padding
            if ~isempty(dlg.elems)
                height = height + dlg.padding*(numel(dlg.elems)-1);
            end

            dlg.totalHeight = height;
            dlg.fig.Position(4) = dlg.totalHeight;

            % Adjust element position
            Ypos = dlg.margin(2);
            for elem = dlg.elems
                elem.Position(2) = Ypos;
                Ypos = Ypos + elem.Position(4) + dlg.padding;
            end
        end

        function close_Cb(dlg, ~)
            dlg.fig.UserData = 's';
        end
    end

    methods (Static, Hidden)
        function selfTest()
            dlg = util.modulardlg();
            dlg.addButton('Hey!', @(varargin)pause(0))
            dlg.addButton('Hey!', @(varargin)pause(0))
            dlg.show()
        end
    end
end

