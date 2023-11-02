function [out, hgfx] = selectPts(ax, type, varargin)
%selectPts   Function for various types of selection with visual feedback
%
%   USAGE
%       points = selectPts(ax, type)
%       points = selectPts(___, Name, Value)
%       [points, hgfx] = selectPts(___)
%
%   DESCRIPTION
%       selectPts allows you to identify the coordinates of points in the
%       given axes. To choose a point, move your cursor to the desired
%       location and press the left mouse button. Press the right mouse
%       button to cancel or end the selection at any moment.
%
%   INPUT PARAMETERS
%       ax      - Axes used for selection. If ax is empty a new Cartesian
%                 axes object if created
%       type    - Type of selection entered as a character array. The
%                 available options are: <point,line, polyline, area, pose>
%
%   OUTPUT PARAMETERS
%       points  - 2-by-n matrix containing the X and Y coordinates of the
%                 selected points
%       hgfx    - Graphic object handle of the graphic objects used during
%                 selection. If handle is not returned all graphic objects
%                 are deleted.
%
%   DETAILS
%       Selection types:
%           - Point: Select a single point in the given axes. Returns the
%           coordiantes of the selected point.
%
%           - Line: Select two points that form a line segment in the given 
%           axes. Returns the start and end coordinates of the line segment.
%
%           - Polyline: Select points until the right mouse button is
%           pressed. Returns the coordinates of the selected points.
%
%           - Area: Select an area described by the space enclosed in a
%           polygon. Returns the coordinates of the polygon vertices.
%
%           - Pose: Select a 2D pose formed by a cartesian position and an
%           angle. Returns a 1-by-3 vector containing the X, Y and
%           orientation values. X and Y are cartesian coordinates in the
%           axes units. The orientation is given in radians and describes a
%           counter-clockwise rotation starting at X+ axis
%
% @file   selectPts.m
% @author Ricard Bitriá Ribes
% Created Date: 07-2023
% -----
% Last Modified: 25-09-2023
% -----
%
    opts = parseInput(type, varargin);

    if isempty(ax)
        ax = axes();
        axis(ax, [1 10 1 10]);
    end

    [gui, prevState] = initGUI(ax);

    if isempty(gui)
        out = [];
        return;
    end

    % State structure
    gui.numPts = 0;
    gui.idx = opts.insertID;

    % Set callbacks
    gui.fig.WindowButtonDownFcn = @mouseBtnDwn;
    gui.fig.WindowButtonMotionFcn = @(src, evt)updateCrossHair(gui.fig, gui.crosshair);
    gui.fig.WindowButtonUpFcn = @mouseBtnUp;

    % Initialize default points
    if ~isempty(opts.defPtsX)
        gui = updtGObj(gui, opts, opts.defPtsX, opts.defPtsY);
    end

    % Wait for user input
    uiwait(gui.fig)

    % If figure has been deleted return
    if ~isvalid(gui.fig)
        out = [];
        hgfx = [];
        return
    end

    % Restore gui state
    gui = resetGUI(gui, prevState);

    % Return graphic objects if requested
    if nargout < 2 || isempty(out)
        % If a graphic object was used
        if isfield(gui, 'hgfx')
            delete(gui.hgfx);
        end
        hgfx = [];
    else
        switch lower(opts.type)
            case {'line', 'polyline'}
                % Remove last point
                gui.hgfx.XData(end) = [];
                gui.hgfx.YData(end) = [];
            case 'area'
                % In patches removing points from XData also removes them from YData
                gui.hgfx.XData(end) = [];
        end
        hgfx = gui.hgfx;
    end

    function mouseBtnDwn(src, ~)
        seltype = src.SelectionType;
        if ~strcmp(seltype,'normal') % If not Left click, return
            return
        end
        
        % Get mouse position
        cp = gui.ax.CurrentPoint;
        xp = cp(1,1);
        yp = cp(1,2);

        [gui, endSelect] = updtGObj(gui, opts, xp, yp);

        if endSelect
            uiresume;
        elseif gui.numPts >= opts.minMaxPoints(2)
            % Entered maximum number of points
            xp = [gui.hgfx.XData(1:gui.idx-1) gui.hgfx.XData(gui.idx+1:end)];
            yp = [gui.hgfx.YData(1:gui.idx-1) gui.hgfx.YData(gui.idx+1:end)];
            out = [xp' yp'];
            uiresume; % Return from main function
        end
    end

    function mouseUpdtLine(~, ~)
        updateCrossHair(gui.fig, gui.crosshair)
        cp = gui.ax.CurrentPoint;
        xp = cp(1,1);
        yp = cp(1,2);
        gui.hgfx.XData(gui.idx) = xp;
        gui.hgfx.YData(gui.idx) = yp;
        drawnow limitrate
    end

    function mouseUpdtRect(~,~)
        cp = gui.ax.CurrentPoint;
        xp = cp(1,1);
        yp = cp(1,2);
        gui.hgfx.XData(2:4) = [xp;xp;gui.hgfx.XData(1)];
        gui.hgfx.YData(2:4) = [gui.hgfx.YData(1);yp;yp];
        drawnow limitrate
    end

    function mouseUpdtPose(~, ~)
        xp1 = out(1);
        yp1 = out(2);

        cp = gui.ax.CurrentPoint;
        xp2 = cp(1,1);
        yp2 = cp(1,2);

        rho = atan2(yp2-yp1, xp2-xp1);
        r = opts.radius;
        d = opts.length;
        gui.hgfx(2).XData = [xp1+r*cos(rho), xp1+d*cos(rho)];
        gui.hgfx(2).YData = [yp1+r*sin(rho), yp1+d*sin(rho)];
        drawnow limitrate
    end
    
    function mouseBtnUp(src, ~)
        last_seltype = src.SelectionType;
        if strcmp(last_seltype,'alt') % Right click
            % Finish selection
            if gui.numPts < opts.minMaxPoints(1)
                % Return empty
                out = [];
            else
                out = [gui.hgfx.XData(:), gui.hgfx.YData(:)];
                out(gui.idx,:) = []; % Romove last edit point
            end
            uiresume; % Return from main function
        end
    end

    function [gui, resume] = updtGObj(gui, opts, xp, yp)
        resume = false;
        switch lower(opts.type)
            case 'point'
                out = [xp(1), yp(1)];
                gui.hgfx = line(xp(1),yp(1), 'Parent', gui.ax, opts.args{:});
                resume = true; % Return from main function
            case {'line', 'polyline'}
                if isfield(gui, 'hgfx')
                    gui.numPts = gui.numPts+1;
                    % Set point and create new one
                    gui.hgfx.XData = [gui.hgfx.XData(1:gui.idx-1), xp, xp, gui.hgfx.XData(gui.idx+1:end)];
                    gui.hgfx.YData = [gui.hgfx.YData(1:gui.idx-1), yp, yp, gui.hgfx.YData(gui.idx+1:end)];
                    gui.idx = gui.idx+1;
                else
                    % First point
                    gui.numPts = numel(xp);

                    title(gui.ax, 'Left click to place points, right click to end')

                    if gui.idx == -1
                        gui.idx = gui.numPts;
                        gui.hgfx = line([xp(1:gui.idx); xp(gui.idx:end)], ...
                        [yp(1:gui.idx); yp(gui.idx:end)], 'Parent', gui.ax, opts.args{:});
                        gui.idx = gui.idx+1;
                    else
                        gui.hgfx = line([xp(1:gui.idx); xp(gui.idx:end)], ...
                            [yp(1:gui.idx); yp(gui.idx:end)], 'Parent', gui.ax, opts.args{:});
                    end
        
                    gui.fig.WindowButtonMotionFcn = @mouseUpdtLine;
                end
            case 'pose'
                if isfield(gui, 'hgfx')
                    % Direction point
                    out = [out, atan2(yp-out(2), xp-out(1))];
                    resume = true; % Return from main function
                else
                    % First point
                    gui.numPts = 1;

                    % Save position
                    out = [xp, yp];

                    % Draw robot
                    k = linspace(0,2*pi,20);
                    r = opts.radius;
                    d = opts.length;
                    gui.hgfx(1) = line(xp + r.*cos(k), yp + r.*sin(k), 'Parent', gui.ax, opts.args{:});
                    gui.hgfx(2) = line([xp+r xp+d], [yp yp], 'Parent', gui.ax, opts.args{:});
                    gui.hgfx(2).Color = gui.hgfx(1).Color;

                    title(gui.ax, 'Left click to select orientation, right click to cancel')

                    gui.fig.WindowButtonMotionFcn = @mouseUpdtPose;
                    % Remove crosshair
                    delete(gui.crosshair)

                    % Show pointer
                    gui.fig.Pointer = 'arrow';
                end
            case 'rectangle'
                if isfield(gui, 'hgfx')
                    out = [gui.hgfx.XData(1), xp; gui.hgfx.YData(1), yp];
                    resume = true; % Return from main function
                else
                    % First point
                    gui.numPts = numel(xp);

                    title(gui.ax, 'Left click to place points, right click to end')

                    gui.hgfx = patch([xp; xp+1; xp+1; xp], ...
                        [yp;yp;yp-1;yp-1], 'r', 'Parent', gui.ax, opts.args{:});

                    gui.fig.WindowButtonMotionFcn = @mouseUpdtRect;
                    % Remove crosshair
                    delete(gui.crosshair)
                end
            case 'area'
                if isfield(gui, 'hgfx')
                    gui.numPts = gui.numPts+1;
                    % Set point and create new one
                    gui.hgfx.XData = [gui.hgfx.XData(1:gui.idx-1)', xp, xp, gui.hgfx.XData(gui.idx+1:end)'];
                    gui.hgfx.YData = [gui.hgfx.YData(1:gui.idx-1)', yp, yp, gui.hgfx.YData(gui.idx+1:end)'];
                    gui.idx = gui.idx+1;
                else
                    % First point
                    gui.numPts = numel(xp);

                    title(gui.ax, 'Left click to place points, right click to end')

                    if gui.idx == -1
                        gui.idx = gui.numPts;
                        gui.hgfx = patch([xp(1:gui.idx); xp(gui.idx:end)], ...
                            [yp(1:gui.idx); yp(gui.idx:end)], 'r', 'Parent', gui.ax, opts.args{:});
                        gui.idx = gui.idx+1;
                    else
                        gui.hgfx = patch([xp(1:gui.idx); xp(gui.idx:end)], ...
                            [yp(1:gui.idx); yp(gui.idx:end)], 'r', 'Parent', gui.ax, opts.args{:});
                    end

                    gui.fig.WindowButtonMotionFcn = @mouseUpdtLine;
                end
            case 'angle'
        end
    end
end

function options = parseInput(type, args)
    % Set defaults
    options.minmaxlines = [1 Inf];
    options.args = {};
    options.defPtsX = [];
    options.defPtsY = [];
    options.insertID = -1;

    % Check type
    switch lower(type)
        case 'point'
            allowedOpts = {'Color', 'LineStyle', 'LineWidth', 'Marker', 'MarkerSize', 'MarkerEdgeColor', 'MarkerFaceColor'};
            options.minMaxPoints = [1 1];
            if numel(args) < 2
                options.args = {'Marker', 'x'};
            end
        case {'line', 'angle'}
            allowedOpts = {'Color', 'LineStyle', 'LineWidth', 'Marker', 'MarkerSize', 'MarkerEdgeColor', 'MarkerFaceColor', 'DefaultPoints', 'InsertIndex'};
            options.minMaxPoints = [2 2];
        case 'polyline'
            allowedOpts = {'Color', 'LineStyle', 'LineWidth', 'Marker', 'MarkerSize', 'MarkerEdgeColor', 'MarkerFaceColor', 'minMaxPoints', 'DefaultPoints', 'InsertIndex'};
            options.minMaxPoints = [2 Inf];
        case 'pose'
            allowedOpts = {'Color', 'LineStyle', 'LineWidth', 'Marker', 'MarkerSize', 'MarkerEdgeColor', 'MarkerFaceColor', 'DefaultPoints', 'InsertIndex'};
            options.minMaxPoints = [2 2];
            options.radius = 0.27;
            options.length = 0.6;
        case 'rectangle'
            allowedOpts = {'FaceColor', 'FaceAlpha', 'EdgeColor', 'EdgeAlpha',...
                'LineStyle', 'LineWidth', 'Marker', 'MarkerSize', 'MarkerEdgeColor',...
                'MarkerFaceColor', 'DefaultPoints', 'InsertIndex'};
            options.minMaxPoints = [2 2];
            if numel(args) < 1
                options.args = {'FaceAlpha', 0};
            end
        case 'area'
            allowedOpts = {'FaceColor', 'FaceAlpha', 'EdgeColor', 'EdgeAlpha',...
                'LineStyle', 'LineWidth', 'Marker', 'MarkerSize', 'MarkerEdgeColor',...
                'MarkerFaceColor', 'minMaxPoints', 'DefaultPoints', 'InsertIndex'};
            options.minMaxPoints = [3 Inf];
            if numel(args) < 1
                options.args = {'FaceAlpha', 0.2};
            end
        otherwise
            error('Unrecognized type %s', type);
    end
    options.type = type;

    % Parse variable arguments
    if mod(numel(args),2) == 0
        % Reorder properties
        idx = find(strcmpi(args, 'minmaxpoints'),1);
        if ~isempty(idx)
            args = [args(idx), args(idx+1), args];
            args([idx+2, idx+3]) = [];
        end

        % Parse Name-Value pairs
        for ii = 1:2:numel(args)-1
            name = args{ii};
            value = args{ii+1};
            
            if ~any(strcmpi(name, allowedOpts))
                error('Unrecognized property ''%s'' for type ''%s'' selection.', name, type)
            end

            switch lower(name)
                case 'minmaxpoints'
                    if any(size(value) ~= [1 2])
                        error('minMaxPoints property expects a 1-by-2 matrix');
                    elseif value(1) > value(2)
                        error('Second element of minMaxPoints property must be greather than or equal to the first element')
                    elseif value(1) < options.minMaxPoints(1)
                        error('First element of minMaxPoints property must be greather than %d for type ''%s'' selection', options.minMaxPoints(1), type)
                    elseif value(2) > options.minMaxPoints(2)
                        error('Second element of minMaxPoints property must be less than %d for type ''%s'' selection', options.minMaxPoints(2), type)
                    else
                        options.minMaxPoints = value;
                    end
                case 'defaultpoints'
                    if size(value,2) ~= 2
                        error('Invalid points size. It must be a n-by-2 matrix')
                    elseif size(value, 1) >= options.minMaxPoints(2)
                        if options.minMaxPoints(2) == 2
                            error('Default points must be a 1-by-2 matrix')
                        else
                            error('Default points must be a n-by-2 matrix with LESS than %d rows', options.minMaxPoints(2))
                        end
                    else
                        options.defPtsX = value(:,1);
                        options.defPtsY = value(:,2);
                    end
                case 'insertindex'
                    if ~all(size(value) == [1 1])
                        error('InserIndex must be a scalar')
                    end
                    options.insertID = value;
                otherwise
                    options.args = [options.args, name, value];
            end
        end
    else
        error('Incorrect number of Name-Value pairs')
    end

    if isempty(options.defPtsX)
        options.insertID = -1;
    end
end

% Initialize graphic objects and store current figure state
function [gui, initState] = initGUI(ax)
    % Get parent figure
    gui.fig = ancestor(ax,'figure','toplevel');
    if isempty(gui.fig) || ~isvalid(gui.fig)
        gui = [];
        return;
    end
    
    gui.ax = ax;

    % Suspend figure functions
    initState.uisuspendState = uisuspend(gui.fig);

    % Disable Plottools Buttons
    initState.toolbar = findobj(allchild(gui.fig),'flat','Type','uitoolbar');
    if ~isempty(initState.toolbar)
        initState.ptButtons = [uigettool(initState.toolbar,'Plottools.PlottoolsOff'), ...
            uigettool(initState.toolbar,'Plottools.PlottoolsOn')];
        initState.ptState = get(initState.ptButtons,'Enable');
        set(initState.ptButtons,'Enable','off');
    end
    
    % Disable AxesToolbar
    if util.getMatlabVersion > 2020
        initState.axes = findobj(allchild(gui.fig),'-isa','matlab.graphics.axis.AbstractAxes');
        tb = get(initState.axes, 'Toolbar');
        if ~isempty(tb) && ~iscell(tb)
            initState.toolbarVisible{1} = tb.Visible;
            tb.Visible = 'off';
        else
            for i=1:numel(tb)
                if ~isempty(tb{i})
                    initState.toolbarVisible{i} = tb{i}.Visible;
                    tb{i}.Visible = 'off';
                end
            end
        end
    end
    
    % Store previous title
    initState.prevTitle = ax.Title.String;
    % Set message
    title(gui.ax, 'Left click to place point, right click to cancel')

    % Disable axis automatic limits
    initState.XLimMode = gui.ax.XLimMode;
    initState.YLimMode = gui.ax.YLimMode;
    gui.ax.XLimMode = 'manual';
    gui.ax.YLimMode = 'manual';

    % Store pointer state
    initState.Pointer = gui.fig.Pointer;
    initState.PointerShapeCData = gui.fig.PointerShapeCData;
    initState.PointerShapeHotSpot = gui.fig.PointerShapeHotSpot;

    % Setup empty pointer
    cdata = NaN(16,16);
    hotspot = [8,8];
    gui.fig.Pointer = 'custom';
    gui.fig.PointerShapeCData = cdata;
    gui.fig.PointerShapeHotSpot = hotspot;

    % Store previous callbacks
    initState.WindowButtonDownFcn = gui.fig.WindowButtonDownFcn;
    initState.WindowButtonMotionFcn = gui.fig.WindowButtonMotionFcn;
    initState.WindowButtonUpFcn = gui.fig.WindowButtonUpFcn;
    
    % Create CrossHair
    gui.crosshair = createCrossHair(gui.fig);
end

% Restore figure to initial state and resume execution
function gui = resetGUI(gui, initState)
    % Restore callbacks
    gui.fig.WindowButtonDownFcn = initState.WindowButtonDownFcn;
    gui.fig.WindowButtonMotionFcn = initState.WindowButtonMotionFcn;
    gui.fig.WindowButtonUpFcn = initState.WindowButtonUpFcn;

    delete(gui.crosshair)

    % Restore Plottools Buttons
    if ~isempty(initState.toolbar) && ~isempty(initState.ptButtons)
        set(initState.ptButtons(1),'Enable',initState.ptState{1});
        set(initState.ptButtons(2),'Enable',initState.ptState{2});
    end
    
    % Restore axestoolbar
    if util.getMatlabVersion > 2020
        for i=1:numel(initState.axes)
            if ~isempty(initState.axes(i).Toolbar)
                initState.axes(i).Toolbar.Visible_I = initState.toolbarVisible{i};
            end
        end
    end

    % Restore axis limits mode
    initState.XLimMode = gui.ax.XLimMode;
    initState.YLimMode = gui.ax.YLimMode;

    % Restore title
    title(gui.ax, initState.prevTitle)

    % UISUSPEND
    uirestore(initState.uisuspendState);

    % Restore pointer
    gui.fig.Pointer = initState.Pointer;
    gui.fig.PointerShapeCData = initState.PointerShapeCData;
    gui.fig.PointerShapeHotSpot = initState.PointerShapeHotSpot;
end

function crossHair = createCrossHair(fig)
% Create thin uicontrols with black backgrounds to simulate fullcrosshair pointer.
% 1: horizontal left, 2: horizontal right, 3: vertical bottom, 4: vertical top

    for k = 1:4
        crossHair(k) = uicontrol(fig, 'Style', 'text', 'Visible', 'off', 'Units', 'pixels', 'BackgroundColor', [0 0 0], 'HandleVisibility', 'off', 'HitTest', 'off'); %#ok<AGROW>
    end
end

function updateCrossHair(fig, crossHair)
    % update cross hair for figure.
    gap = 3; % 3 pixel view port between the crosshairs
    cp = hgconvertunits(fig, [fig.CurrentPoint 0 0], fig.Units, 'pixels', fig);
    cp = cp(1:2);
    figPos = hgconvertunits(fig, fig.Position, fig.Units, 'pixels', fig.Parent);
    figWidth = figPos(3);
    figHeight = figPos(4);
    
    % Early return if point is outside the figure
    if cp(1) < gap || cp(2) < gap || cp(1)>figWidth-gap || cp(2)>figHeight-gap
        return
    end
    
    set(crossHair, 'Visible', 'on');
    thickness = 1; % 1 Pixel thin lines. 
    set(crossHair(1), 'Position', [0 cp(2) cp(1)-gap thickness]);
    set(crossHair(2), 'Position', [cp(1)+gap cp(2) figWidth-cp(1)-gap thickness]);
    set(crossHair(3), 'Position', [cp(1) 0 thickness cp(2)-gap]);
    set(crossHair(4), 'Position', [cp(1) cp(2)+gap thickness figHeight-cp(2)-gap]);
end