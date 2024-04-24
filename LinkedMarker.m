classdef LinkedMarker < handle
    %DATAMARKER Summary of this class goes here
    %   Detailed explanation goes here
    
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

        updtListener = event.listener.empty();
        deleteListener = event.listener.empty();
    end
    
    methods
        function obj = LinkedMarker(inAxes, outAxes, inData, outData)
            validateattributes(inAxes, 'matlab.graphics.axis.Axes', {'nonempty'}, 'DataMarker', 'inAxes')
            validateattributes(outAxes, 'matlab.graphics.axis.Axes', {'nonempty'}, 'DataMarker', 'outAxes')
            validateattributes(inData, 'numeric', {'nonempty', 'finite', 'real', 'ncols', 2}, 'DataMarker', 'inData')
            nrows = size(inAxes, 1);
            validateattributes(outData, 'numeric', {'nonempty', 'finite', 'real', 'vector', 'nrows', nrows}, 'DataMarker', 'outData')

            obj.inAxes = inAxes;
            obj.inData = inData;
            obj.outData = outData;
            obj.inMarker = gobjects(0);
            obj.outMarker = gobjects(0);

            % Get parent figure
            obj.inFigure = ancestor(inAxes,'figure','toplevel');

            % Create marker in inAxes
            obj.inMarker = line(nan, nan, 'Parent', inAxes, 'Marker', 'x', 'Color', 'r', 'MarkerSize', 20);
            obj.inMarker.Annotation.LegendInformation.IconDisplayStyle = 'off';

            % Create vertical marker in target axes
            obj.outMarker = gobjects(1,numel(outAxes));
            for ii = 1:numel(outAxes)
                % Create vertical line
                if util.getMatlabVersion >= 2018.5
                    obj.outMarker(ii) = xline(nan, 'Parent', outAxes(ii), 'LineWidth', 2, 'Color', [0.15 0.15 0.15]);
                else
                    obj.outMarker(ii) = line([nan nan], [outAxes(ii).YLim], 'Parent', outAxes(ii), 'LineWidth', 2, 'Color', [0.15 0.15 0.15], 'LineStyle', '--');
                end
                obj.outMarker(ii).Annotation.LegendInformation.IconDisplayStyle = 'off';

                % Try to delete data marker when the marker is deleted
                obj.deleteListener(ii) = addlistener(obj.outMarker(ii), 'ObjectBeingDestroyed', @(o,e)obj.outMarkerDeleted());
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
        
        function outMarkerDeleted(obj)
            % Check for valid markers
            if ~any(isvalid(obj.outMarker))
                % If there are no valid markers remaining, delete DataMarker
                delete(obj);
            end
        end

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

            % If there are no valid markers remaining, delete DataMarker
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

            % If there are no valid markers remaining, delete DataMarker
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

