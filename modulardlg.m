classdef modulardlg < handle
    %MODULARDLG Object for easy input dialog creation
    %   This object creates a fully configurable input dialog
    
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
        elems = struct('hdle', gobjects(0), 'type', '', 'weight', 1, 'size', [], 'Children', [], 'Parent', []);
        outElems = struct('var', '', 'id', 0);

        activeElement = 0;

        exitButtonID = -1;
    end

    properties (Constant, Access = private)
        minWidth = 200;
        minHeight = 20;
    end
    
    methods
        function dlg = modulardlg()
            %PROMPTDLG Construct an instance of this class
            %   Detailed explanation goes here

            % Delete all elements
            dlg.elems(:) = [];
            dlg.outElems(:) = [];

            dlg.fig = figure(...
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
            % SHOW Show the dialog and wait for the user
            %   show(dlg)
            %
            % Input:
            %   dlg     - modulardlg object
            %
            % Return:
            %   answer  - Structure with the user input values
            %   button  - String of the button pressed when closing the dialog

            dlg.fig.Visible = 'on';
            waitfor(dlg.fig, 'UserData', 's');

            answer = dlg.constructAnswer();
            if dlg.exitButtonID > 0
                button = dlg.elems(dlg.exitButtonID).hdle.String;
            else
                button = '';
            end

            delete(dlg.fig)
        end

        function outId = addButton(dlg, txt, varName, varargin)
            % ADDBUTTON
            %   addButton(dlg, txt, varName)
            %   addButton(__, Name, Value)
            %
            % Input:
            %   dlg     - modulardlg object
            %   txt     - Text displayed inside the button
            %   varName - Name of the variable where the state of the button will be stored
            % Return:
            %   outId   - Element ID
            id = dlg.registerElement('Button', varargin{:});
            hdle = uicontrol(...
                'style'   , 'pushbutton',...
                'parent'  , dlg.fig,...
                'string'  , txt,...
                'position', [dlg.padding(1),dlg.padding(2), dlg.controlWidth/2.5, dlg.controlHeight*1.5],...
                'FontSize', dlg.fontsize,...
                'Callback', @(src, evt)dlg.pushButton_Cb(id));

            dlg.elems(id).hdle = hdle;
            dlg.registerOutput(varName, id);
            dlg.draw()

            if nargout > 0
                outId = id;
            end
        end

        function outId = addEdit(dlg, txt, varName, varargin)

            hdle = uicontrol(...
                'style'   , 'edit',...
                'parent'  , dlg.fig,...
                'string'  , txt,...
                'position', [dlg.padding(1),dlg.padding(2), dlg.controlWidth, dlg.controlHeight],...
                'FontSize', dlg.fontsize);

            id = dlg.registerElement('Edit', hdle, varargin{:});
            dlg.registerOutput(varName, id);

            dlg.draw()

            if nargout > 0
                outId = id;
            end
        end

        function outId = addOkCancel(dlg)
            id = dlg.addHBox('size', [80, 30], 'weight', 0);
            dlg.addSpacer();
            dlg.addButton('Ok', 'Ok', 'size', [80, 30], 'weight', 0);
            dlg.addButton('Cancel', 'Cancel', 'size', [80, 30], 'weight', 0)
            dlg.addSpacer();
            dlg.endBox();

            if nargout > 0
                outId = id;
            end
        end

        function outId = addHBox(dlg, varargin)
            id = dlg.registerElement('HBox', varargin{:});

            % Set as the active element
            dlg.activeElement = id;

            dlg.draw()

            if nargout > 0
                outId = id;
            end
        end

        function outId = addVBox(dlg, varargin)
            id = dlg.registerElement('VBox', varargin{:});

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

        function outId = addSpacer(dlg, varargin)
            id = dlg.registerElement('Spacer', varargin{:});
            dlg.draw()

            if nargout > 0
                outId = id;
            end
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
        function parseInput(varargin)
        end

        function id = registerElement(dlg, type, varargin)
            % Create new entry in the array and assign type
            dlg.elems(end+1).type = type;
            id = numel(dlg.elems);

            % Assign parent
            dlg.elems(id).Parent = dlg.activeElement;

            % Assign new element to the current active element
            if dlg.activeElement == 0
                dlg.root.Children(end+1) = id;
            else
                dlg.elems(dlg.activeElement).Children(end+1) = id;
            end

            % Set additional parameters
            switch dlg.elems(id).type
                case {'Edit'}
                    validateattributes(varargin{1}, {'matlab.ui.control.UIControl'}, {'scalar'});
                    dlg.elems(id).hdle = varargin{1};
                    varargin(1) = [];
            end

            % Create parser
            p = inputParser();
            p.addParameter('weight', 1, @(x)validateattributes(x, {'numeric'}, {'scalar', 'finite', 'real'}));
            p.addParameter('size', [0 0], @(x)validateattributes(x, {'numeric'}, {'vector', 'finite', 'real', 'numel', 2, 'nonnegative'}));

            p.parse(varargin{:});

            % Set properties
            dlg.elems(id).weight = p.Results.weight;
            dlg.elems(id).size = p.Results.size;
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
            elemSz = vertcat(dlg.elems(elem.Children).size);

            childWeight = [dlg.elems(elem.Children).weight];
            totalWeight = sum(childWeight);

            % Fixed size elements
            fixElems = childWeight == 0;

            switch elem.type
                case 'HBox'
                    % Weighted width elements
                    remWidth = elem.size(1) - sum(elemSz(fixElems, 1)) - dlg.spacing*(numel(elem.Children)-1);
                    remWidth = max(remWidth, 0);
                    elemSz(~fixElems, 1) = remWidth/totalWeight * childWeight(~fixElems);

                    % Set height
                    elemSz(:, 2) = elem.size(2);
                case 'VBox'
                    % Weighted height elements
                    remHeight = elem.size(2) - sum(elemSz(fixElems, 2)) - dlg.spacing*(numel(elem.Children)-1);
                    remHeight = max(remHeight, 0);
                    elemSz(~fixElems, 2) = remHeight/totalWeight * childWeight(~fixElems);

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
            dlg.root = dlg.setElemSize(dlg.root, [dlg.Position(3)-dlg.padding(1)-dlg.padding(3), dlg.Position(4)-dlg.padding(2)-dlg.padding(4)]);
            dlg.drawElement(dlg.root, [dlg.padding(1), dlg.Position(4)-dlg.padding(4)]);
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
            dlg.addVBox('weight', 2);
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

