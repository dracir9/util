classdef modulardlg < handle
    %PROMPTDLG Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        fig     matlab.ui.Figure

        spacing = 5;
        padding = [5, 5, 5, 5];
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
        root = struct('type', 'VBox', 'size', [], 'Children', []);
        elems = struct('hdle', gobjects(0), 'type', '', 'weight', -1, 'size', [], 'Children', [], 'Parent', []);
        outElems = struct('var', '', 'id', 0);

        activeElement = 0;

        exitButtonID = -1;
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
            dlg.outElems(:) = [];

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
             'CloseRequestFcn' , @(src, evt)close_Cb(dlg));% Close callback

            dlg.Position = [scx, scy, dlg.minWidth, dlg.minHeight];

            dlg.bgcolor = get(0, 'defaultUicontrolBackgroundColor');
            dlg.fontsize = get(0, 'defaultuicontrolfontsize');

            dlg.controlWidth = 125;
            dlg.controlHeight = max(18, (dlg.fontsize+6));

            dlg.root.size = dlg.Position(3:4);
        end

        function delete(dlg)
            delete(dlg.fig)
        end

        function [answer, button] = show(dlg)
            dlg.fig.Visible = 'on';
            waitfor(dlg.fig, 'UserData', 's');

            answer = dlg.constructAnswer();
            button = dlg.elems(dlg.exitButtonID).hdle.String;

            delete(dlg.fig)
        end

        function outId = addButton(dlg, txt, varName)
            id = dlg.registerElement('Button');

            dlg.elems(id).hdle = uicontrol(...
                'style'   , 'pushbutton',...
                'parent'  , dlg.fig,...
                'string'  , txt,...
                'position', [dlg.padding(1),dlg.padding(2), dlg.controlWidth/2.5, dlg.controlHeight*1.5],...
                'FontSize', dlg.fontsize,...
                'Callback', @(src, evt)dlg.pushButton_Cb(id));

            dlg.registerOutput(varName, id);
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
                'position', [dlg.padding(1),dlg.padding(2), dlg.controlWidth, dlg.controlHeight],...
                'FontSize', dlg.fontsize);

            dlg.registerOutput(varName, id);

            dlg.draw()

            if nargout > 0
                outId = id;
            end
        end

        function outId = addOkCancel(dlg)
            id = dlg.addHBox();
            dlg.addButton('Ok', 'Ok');
            dlg.addButton('Cancel', 'Cancel')
            dlg.endBox();

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

        function outId = addVBox(dlg)
            id = dlg.registerElement('VBox');

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

            % Set default weight
            dlg.elems(id).weight = -1;

            % Assign children
            if dlg.activeElement == 0
                dlg.root.Children(end+1) = id;
            else
                dlg.elems(dlg.activeElement).Children(end+1) = id;
            end
        end

        function registerOutput(dlg, varName, id)
            dlg.outElems(end+1).var = varName;
            dlg.outElems(end).id = id;
        end

        function elem = setElemSize(dlg, elem, maxSz)
            elem.size = maxSz;

            if numel(elem.Children) == 0
                return
            end
            elemSz = zeros(numel(elem.Children), 2);

            % Fixed size elements
            fixElems = [dlg.elems(elem.Children).weight] > 0;

            switch elem.type
                case 'HBox'
                    % Fixed width elements
                    elemSz(fixElems, 1) = [dlg.elems(fixElems).weight];

                    % Weighted width elements
                    remWidth = elem.size(1) - sum(elemSz(fixElems, 1)) - dlg.spacing*(numel(elem.Children)-1);
                    remWidth = max(remWidth, 0);
                    elemSz(~fixElems, 1) = remWidth/(sum(~fixElems));

                    % Set height
                    elemSz(:, 2) = elem.size(2);
                case 'VBox'
                    % Fixed height elements
                    elemSz(fixElems, 2) = [dlg.elems(fixElems).weight];

                    % Weighted height elements
                    remHeight = elem.size(2) - sum(elemSz(fixElems, 2)) - dlg.spacing*(numel(elem.Children)-1);
                    remHeight = max(remHeight, 0);
                    elemSz(~fixElems, 2) = remHeight/(sum(~fixElems));

                    % Set width
                    elemSz(:, 1) = elem.size(1);
                otherwise
                    error('Invalid type')
            end

            % Assign child sizes
            for ii = 1:numel(elem.Children)
                dlg.elems(elem.Children(ii)) = dlg.setElemSize(dlg.elems(elem.Children(ii)), elemSz(ii, :));
            end
        end

        function draw(dlg)
            dlg.Position(3:4) = [500, 500];
            dlg.root = dlg.setElemSize(dlg.root, [500-dlg.padding(1)-dlg.padding(3), 500-dlg.padding(2)-dlg.padding(4)]);
            dlg.drawElement(dlg.root, [0+dlg.padding(1), 500-dlg.padding(4)]);
        end

        function drawElement(dlg, elem, origin)
            if numel(elem.Children) == 0
                origin(2) = origin(2) - elem.size(2);
                elem.hdle.Position = [origin, elem.size];
            else
                childs = dlg.elems(elem.Children);
                step = vertcat(childs.size);
                switch elem.type
                    case 'HBox'
                        step(:,1) = step(:,1) + dlg.spacing;
                        step(:,2) = 0;
                    case 'VBox'
                        step(:,1) = 0;
                        step(:,2) = step(:,2) + dlg.spacing;
                end
                step(:, 2) = -step(:, 2);

                for ii = 1:numel(childs)
                    dlg.drawElement(childs(ii), origin);
                    origin = origin + step(ii, :);
                end
            end
        end

        function answer = constructAnswer(dlg)
            for ii = 1:numel(dlg.outElems)
                if dlg.outElems(ii).id == dlg.exitButtonID
                    val = 1;
                else
                    val = dlg.elems(dlg.outElems(ii).id).hdle.Value;
                end
                answer.(dlg.outElems(ii).var) = val;
            end
        end

        function close_Cb(dlg)
            dlg.fig.UserData = 's';
        end

        function pushButton_Cb(dlg, id)
            dlg.exitButtonID = id;
            dlg.close_Cb();
        end
    end

    methods (Static, Hidden)
        function selfTest()
            dlg = util.modulardlg();
            dlg.addButton('Hey!', 'but1');
            dlg.addHBox();
            dlg.addEdit('Def', 'myvar');
            dlg.addVBox();
            dlg.addButton('Hey!', 'but2')
            dlg.addButton('Hey!', 'but3')
            dlg.endBox();
            dlg.addEdit('Test', 'var');
            dlg.endBox();
            dlg.addEdit('Final', 'var2');
            dlg.addOkCancel();
            [a, b] = dlg.show()
        end
    end
end

