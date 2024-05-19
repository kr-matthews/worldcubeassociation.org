import React, {
  useCallback,
  useEffect,
  useMemo,
} from 'react';
import _ from 'lodash';

import { Button, Card, Message } from 'semantic-ui-react';
import { events } from '../../lib/wca-data.js.erb';

import { useSaveWcifAction } from '../../lib/utils/wcif';
import EventPanel from './EventPanel';
import { changesSaved } from './store/actions';
import wcifEventsReducer from './store/reducer';
import Store, { useDispatch, useStore } from '../../lib/providers/StoreProvider';
import ConfirmProvider from '../../lib/providers/ConfirmProvider';

function EditEvents() {
  const {
    competitionId, wcifEvents, initialWcifEvents, wcifSchedule, initialWcifSchedule,
  } = useStore();
  const dispatch = useDispatch();

  const unsavedChanges = useMemo(() => (
    !_.isEqual(wcifEvents, initialWcifEvents) || !_.isEqual(wcifSchedule, initialWcifSchedule)
  ), [wcifEvents, initialWcifEvents, wcifSchedule, initialWcifSchedule]);

  const onUnload = useCallback((e) => {
    // Prompt the user before letting them navigate away from this page with unsaved changes.
    if (unsavedChanges) {
      const confirmationMessage = 'You have unsaved changes, are you sure you want to leave?';
      e.returnValue = confirmationMessage;
      return confirmationMessage;
    }

    return null;
  }, [unsavedChanges]);

  useEffect(() => {
    window.addEventListener('beforeunload', onUnload);

    return () => {
      window.removeEventListener('beforeunload', onUnload);
    };
  }, [onUnload]);

  const { saveWcif, saving } = useSaveWcifAction();

  const save = useCallback(() => {
    saveWcif(
      competitionId,
      { events: wcifEvents, schedule: wcifSchedule },
      () => dispatch(changesSaved()),
    );
  }, [competitionId, dispatch, saveWcif, wcifEvents, wcifSchedule]);

  const renderUnsavedChangesAlert = () => (
    <Message color="blue">
      You have unsaved changes. Don&apos;t forget to
      {' '}
      <Button
        onClick={save}
        disabled={saving}
        loading={saving}
        color="blue"
      >
        save your changes!
      </Button>
    </Message>
  );

  return (
    <>
      {unsavedChanges && renderUnsavedChangesAlert()}
      <Card.Group
        itemsPerRow={3}
        className="stackable"
        // this is necessary so that the cards "wrap" instead of growing to match the longest card
        style={{ alignItems: 'baseline' }}
      >
        {wcifEvents.map((wcifEvent) => (
          <EventPanel key={wcifEvent.id} wcifEvent={wcifEvent} />
        ))}
      </Card.Group>
      {unsavedChanges && renderUnsavedChangesAlert()}
    </>
  );
}

function normalizeWcifEvents(wcifEvents) {
  // Since we want to support deprecated events and be able to edit their rounds,
  // we want to show deprecated events if they exist in the WCIF, but not if they
  // don't.
  // Therefore we first build the list of events from the official one, updating
  // it with WCIF data if any.
  // And then we add all events that are still in the WCIF (which means they are
  // not official anymore).
  const ret = events.official.map(
    (event) => _.remove(wcifEvents, { id: event.id })[0] || {
      id: event.id,
      rounds: null,
    },
  );
  return ret.concat(wcifEvents);
}

export default function Wrapper({
  competitionId,
  canAddAndRemoveEvents,
  canUpdateEvents,
  canUpdateQualifications,
  wcifEvents,
  wcifSchedule,
}) {
  const normalizedEvents = normalizeWcifEvents(wcifEvents);

  return (
    <Store
      reducer={wcifEventsReducer}
      initialState={{
        competitionId,
        canAddAndRemoveEvents,
        canUpdateEvents,
        canUpdateQualifications,
        wcifEvents: normalizedEvents,
        initialWcifEvents: normalizedEvents,
        wcifSchedule,
        initialWcifSchedule: wcifSchedule,
        unsavedChanges: false,
      }}
    >
      <ConfirmProvider>
        <EditEvents />
      </ConfirmProvider>
    </Store>
  );
}
