classdef LinkedMarker < handle
    %LINKEDMARKER Object that creates a linked data marker between multiple axes
    %   When the user right clicks on the input axes the data markers are automatically updated on the
    %   output axes
    
    properties (SetAccess = private)
        inMarker
        outMarker

        inData
        outData
    end

    properties (Access = private)
        prevTitle
        mousePointer

        inAxes
        inFigure

        outFigure = gobjects(0);
        outAxes = cell(0);

        updtListener = event.listener.empty();
        deleteListener = event.listener.empty();
        reverseListener = event.listener.empty();
    end
    
    methods
        %LINKEDMARKER Create an instance of a LinkedMarker object
        %   LinkedMarker(inAxes, outAxes, inData, outData)
        %
        %   obj = LinkedMarker(inAxes, outAxes, inData, outData) Return LinkedMarker handle
        %
        %   LinkedMarker(__, Name, Value)
        %
        % Inputs:
        %   inAxses     - Primary input axes. Must be a scalar value of type Axes
        %   outAxes     - Output axes. Can be any number of axes provided as an array
        %   inData      - Input data points that maps to the output data. Must be a N-by-2 matrix
        %   outData     - Output data points that maps to the input data. Must have N elements.
        function obj = LinkedMarker(inAxes, outAxes, inData, outData, varargin)
            if nargin == 0
                obj = obj.empty();
                return
            end
            validateattributes(inAxes, {'matlab.graphics.axis.Axes'}, {'scalar'}, 'LinkedMarker', 'inAxes')
            validateattributes(outAxes, {'matlab.graphics.axis.Axes'}, {'nonempty'}, 'LinkedMarker', 'outAxes')
            validateattributes(inData, {'numeric'}, {'nonempty', 'finite', 'real', 'ncols', 2}, 'LinkedMarker', 'inData')
            nrows = size(inData, 1);
            validateattributes(outData, {'numeric'}, {'nonempty', 'finite', 'real', 'vector'}, 'LinkedMarker', 'outData')
            if numel(outData) ~= nrows
                error('Expected outData to be an array with number of elements equal to the number of rows in inData')
            end

            % Create parser
            p = inputParser;
            p.addParameter('Color', 'r', @(x)validatecolor(x, 'one'));
            p.addParameter('LineStyle', '--');
            p.addParameter('LineWidth', 1.5, @(x)validateattributes(x, {'numeric'}, {'scalar', 'finite', 'real', 'positive'}));
            p.addParameter('MarkerSize', 20, @(x)validateattributes(x, {'numeric'}, {'scalar', 'finite', 'real', 'positive'}));
            p.addParameter('ReverseLink', false, @(x)validateattributes(x, {'logical'}, {'scalar'}));

            % Parse name-value pairs
            p.parse(varargin{:})

            % Assign object properties
            obj.inAxes = inAxes;
            obj.inData = inData;
            obj.outData = outData;
            obj.inMarker = gobjects(0);
            obj.outMarker = gobjects(0);

            % Get parent figure
            obj.inFigure = ancestor(inAxes,'Figure','toplevel');

            % Create marker in inAxes
            obj.inMarker(1) = line(nan, nan, 'Parent', inAxes, 'Marker', 'x', 'Color', p.Results.Color, 'MarkerSize', p.Results.MarkerSize, 'LineWidth', p.Results.LineWidth);
            obj.inMarker(2) = line(nan, nan, 'Parent', inAxes, 'Marker', 'o', 'Color', p.Results.Color, 'MarkerSize', p.Results.MarkerSize, 'LineWidth', p.Results.LineWidth);
            obj.inMarker(1).Annotation.LegendInformation.IconDisplayStyle = 'off';
            obj.inMarker(2).Annotation.LegendInformation.IconDisplayStyle = 'off';

            % Create vertical marker in target axes
            obj.outMarker = gobjects(1,numel(outAxes));
            for ii = 1:numel(outAxes)
                % Create vertical line
                if util.getMatlabVersion >= 2018.5
                    obj.outMarker(ii) = xline(nan, 'Parent', outAxes(ii), 'LineWidth', p.Results.LineWidth, 'Color', p.Results.Color, 'LineStyle', p.Results.LineStyle);
                else
                    obj.outMarker(ii) = line([nan nan], [outAxes(ii).YLim], 'Parent', outAxes(ii), 'LineWidth', p.Results.LineWidth, 'Color', p.Results.Color, 'LineStyle', p.Results.LineStyle);
                end
                obj.outMarker(ii).Annotation.LegendInformation.IconDisplayStyle = 'off';

                % Try to delete data marker when the marker is deleted
                obj.deleteListener(ii) = addlistener(obj.outMarker(ii), 'ObjectBeingDestroyed', @(o,e)obj.outMarkerDeleted());

                % Enable reverse interactions (from output axes to input axes)
                if p.Results.ReverseLink
                    obj.addOutAxes(outAxes(ii));
                end
            end

            % Display information on the axes title
            obj.prevTitle = inAxes.Title.String;
            title(inAxes, 'Right click to select a data point')

            % Set input figure mouse pointer as crosshair
            obj.mousePointer = obj.inFigure.Pointer;
            obj.inFigure.Pointer = 'crosshair';

            % Create listener for the button up event
            obj.updtListener = addlistener(obj.inFigure, 'WindowMouseRelease', @(o,e) obj.updateMarker(o));

            % Delete output argument if not needed
            if nargout == 0
                clear obj
            end
        end

        %DELETE Cleanup and delete object instance
        %   delete(obj)
        %
        % Inputs:
        %   obj     - LinkedMarker object handle
        function delete(obj)
            % Restore previous title
            if isvalid(obj.inAxes) && ~isnumeric(obj.prevTitle)
                title(obj.inAxes, obj.prevTitle)
            end

            % Restore pointer
            if isvalid(obj.inFigure) && ~isempty(obj.mousePointer)
                obj.inFigure.Pointer = obj.mousePointer;
            end

            % Delete event listener
            if isvalid(obj.updtListener)
                delete(obj.updtListener);
            end

            for ii = 1:numel(obj.deleteListener)
                if isvalid(obj.deleteListener(ii))
                    delete(obj.deleteListener(ii));
                end
            end

            for ii = 1:numel(obj.reverseListener)
                if isvalid(obj.reverseListener(ii))
                    delete(obj.reverseListener(ii));
                end
            end

            % Delete inMarkers
            for ii = 1:numel(obj.inMarker)
                if isvalid(obj.inMarker(ii))
                    delete(obj.inMarker(ii));
                end
            end

            % Delete outMarkers
            for ii = 1:numel(obj.outMarker)
                if isvalid(obj.outMarker(ii))
                    delete(obj.outMarker(ii));
                end
            end
        end
    end

    methods (Access = private)
        %ADDOUTAXeS Register output axes
        %   addOutAxes(obj) Register output axes and create listener to update the marker in reverse mode
        %
        % Inputs:
        %   obj     - LinkedMarker object handle
        %   ax      - Axes to be registered
        function addOutAxes(obj, ax)
            parentFig = ancestor(ax, 'Figure', 'toplevel');

            outFigIdx = obj.outFigure == parentFig;
            if isempty(obj.outFigure) || ~any(outFigIdx)
                obj.outFigure(end+1) = parentFig;
                obj.outAxes{end+1} = ax;
                id = numel(obj.outFigure);
            else
                id = find(outFigIdx, 1);
                obj.outAxes{id}(end+1) = ax;
            end
            obj.reverseListener(end+1) = addlistener(parentFig, 'WindowMouseRelease', @(o,e) obj.updateInMarker(o, id));
        end

        %OUTMARKERDELETED Output marker deleted event callback
        %   outMarkerDeleted(obj) Function called when an output marker is deleted
        %
        % Inputs:
        %   obj     - LinkedMarker object handle
        function outMarkerDeleted(obj)
            % Check for valid markers
            if ~any(isvalid(obj.outMarker))
                % If there are no valid markers remaining, delete LinkedMarker
                delete(obj);
            end
        end

        %UPDATEMARKER Update output marker event callback
        %   updateMarker(obj) Update the position of the markers
        %
        % Inputs:
        %   obj     - LinkedMarker object handle
        %   src     - Event caller handle
        function updateMarker(obj, src)
            % Right click only
            if ~strcmp(src.SelectionType, 'alt')
                return
            end

            mousePos = obj.inAxes.CurrentPoint(1,1:2);
            posDiff = obj.inData - mousePos;
            dist2Cursor = hypot(posDiff(:,1), posDiff(:,2));
            [~, idx] = min(dist2Cursor);

            % Update primary axes marker
            validMarker = false;
            for ii = 1:numel(obj.inMarker)
                if isvalid(obj.inMarker(ii))
                    obj.inMarker(ii).XData = obj.inData(idx, 1);
                    obj.inMarker(ii).YData = obj.inData(idx, 2);
                    validMarker = true;
                end
            end

            % If there are no valid markers remaining, delete LinkedMarker
            if ~validMarker
                delete(obj);
                return
            end

            % Update secondary axes marker
            validMarker = false;
            for ii = 1:numel(obj.outMarker)
                if isvalid(obj.outMarker(ii))
                    if isprop(obj.outMarker(ii), 'Value')
                        obj.outMarker(ii).Value = obj.outData(idx);
                    else
                        obj.outMarker(ii).XData = obj.outData(idx)*ones(1,2);
                    end
                    validMarker = true;
                end
            end

            % If there are no valid markers remaining, delete LinkedMarker
            if ~validMarker
                delete(obj);
            end
        end

        %UPDATEINMARKER Update input marker event callback
        %   updateInMarker(obj) Update the position of the markers
        %
        % Inputs:
        %   obj     - LinkedMarker object handle
        %   src     - Event caller handle
        %   id      - Index in the outAxes cell array
        function updateInMarker(obj, src, id)
            % Right click only
            if ~strcmp(src.SelectionType, 'alt')
                return
            end

            % Find axes where the cursor was pressed
            axesGroup = obj.outAxes{id}; % Get axes in a figure
            validAxes = false;
            for ii = 1:numel(axesGroup)
                mousePos = axesGroup(ii).CurrentPoint(1,1:2);
                % Check if mouse position is within the axes
                if mousePos(1) > axesGroup(ii).XLim(1) && mousePos(1) < axesGroup(ii).XLim(2) && ...
                   mousePos(2) > axesGroup(ii).YLim(1) && mousePos(2) < axesGroup(ii).YLim(2)
                    validAxes = true;
                    break;
                end
            end

            if ~validAxes
                return
            end

            xDiff = abs(obj.outData - mousePos(1));
            [~, idx] = min(xDiff);

            % Update primary axes marker
            validMarker = false;
            for ii = 1:numel(obj.inMarker)
                if isvalid(obj.inMarker(ii))
                    obj.inMarker(ii).XData = obj.inData(idx, 1);
                    obj.inMarker(ii).YData = obj.inData(idx, 2);
                    validMarker = true;
                end
            end

            % If there are no valid markers remaining, delete LinkedMarker
            if ~validMarker
                delete(obj);
                return
            end

            % Update secondary axes marker
            validMarker = false;
            for ii = 1:numel(obj.outMarker)
                if isvalid(obj.outMarker(ii))
                    if isprop(obj.outMarker(ii), 'Value')
                        obj.outMarker(ii).Value = obj.outData(idx);
                    else
                        obj.outMarker(ii).XData = obj.outData(idx)*ones(1,2);
                    end
                    validMarker = true;
                end
            end

            % If there are no valid markers remaining, delete LinkedMarker
            if ~validMarker
                delete(obj);
            end
        end
    end

    methods (Static, Hidden)
        function selfTest()
            numPts = 100;
            theta = linspace(0, 8*pi, numPts);
            rho = theta;
            [xpts, ypts] = pol2cart(theta, rho);

            t = linspace(0, 10, numPts);
            zpts = rand(1, numPts);

            fig1 = figure();
            fig2 = figure();

            ax1 = axes(fig1);
            ax2 = axes(fig2);

            plot(ax1, xpts, ypts);
            plot(ax2, t, zpts);

            util.LinkedMarker(ax1, ax2, [xpts; ypts]', t)

            % waitfor(fig1);
            % waitfor(fig2);
        end
    end
end

