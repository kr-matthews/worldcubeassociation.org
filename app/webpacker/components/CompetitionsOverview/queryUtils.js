import { DateTime } from 'luxon';

import { competitionConstants } from '../../lib/wca-data.js.erb';

const isContinent = (region) => region[0] === '_';

export function calculateQueryKey(filterState, canViewAdminDetails = false) {
  let timeKey = '';
  if (filterState?.timeOrder === 'past') {
    timeKey = `${filterState.selectedYear}`;
  } else if (filterState?.timeOrder === 'custom') {
    timeKey = `start${filterState.customStartDate}-end${filterState.customEndDate}`;
  }

  const adminStatus = canViewAdminDetails ? filterState?.adminStatus : null;

  return {
    timeOrder: filterState?.timeOrder,
    region: filterState?.region,
    selectedEvents: filterState?.selectedEvents,
    delegate: filterState?.delegate,
    search: filterState?.search,
    time: timeKey,
    shouldIncludeCancelled: filterState?.shouldIncludeCancelled,
    adminStatus,
  };
}

export function createSearchParams(filterState, pageParam, canViewAdminDetails = false) {
  const {
    region,
    selectedEvents,
    delegate,
    search,
    timeOrder,
    selectedYear,
    customStartDate,
    customEndDate,
    adminStatus,
    shouldIncludeCancelled,
  } = filterState;

  const dateNow = DateTime.now();
  const searchParams = new URLSearchParams({});

  if (region && region !== 'all') {
    const regionParam = isContinent(region) ? 'continent' : 'country_iso2';
    searchParams.append(regionParam, region);
  }
  if (selectedEvents && selectedEvents.length > 0) {
    selectedEvents.forEach((eventId) => searchParams.append('event_ids[]', eventId));
  }
  if (delegate) {
    searchParams.append('delegate', delegate);
  }
  if (search) {
    searchParams.append('q', search);
  }
  if (canViewAdminDetails && adminStatus && adminStatus !== 'all') {
    searchParams.append('admin_status', adminStatus);
  }
  searchParams.append('include_cancelled', shouldIncludeCancelled);

  if (timeOrder === 'present') {
    searchParams.append('sort', 'start_date,end_date,name');
    searchParams.append('ongoing_and_future', dateNow.toISODate());
    searchParams.append('page', pageParam);
  } else if (timeOrder === 'recent') {
    // noinspection JSAnnotator
    const recentDaysAgo = dateNow.minus({ days: competitionConstants.competitionRecentDays });

    searchParams.append('sort', '-end_date,-start_date,name');
    searchParams.append('start', recentDaysAgo.toISODate());
    searchParams.append('end', dateNow.toISODate());
    searchParams.append('page', pageParam);
  } else if (timeOrder === 'past') {
    if (selectedYear === 'all_years') {
      searchParams.append('sort', '-end_date,-start_date,name');
      searchParams.append('end', dateNow.toISODate());
      searchParams.append('page', pageParam);
    } else {
      searchParams.append('sort', '-end_date,-start_date,name');
      searchParams.append('start', `${selectedYear}-1-1`);
      searchParams.append('end', dateNow.year === selectedYear ? dateNow.toISODate() : `${selectedYear}-12-31`);
      searchParams.append('page', pageParam);
    }
  } else if (timeOrder === 'by_announcement') {
    searchParams.append('sort', '-announced_at,name');
    searchParams.append('page', pageParam);
  } else if (timeOrder === 'custom') {
    const startLuxon = DateTime.fromISO(customStartDate, { zone: 'UTC' });
    const endLuxon = DateTime.fromISO(customEndDate, { zone: 'UTC' });

    searchParams.append('sort', 'start_date,end_date,name');
    searchParams.append('start', startLuxon.isValid ? startLuxon.toISODate() : '');
    searchParams.append('end', endLuxon.isValid ? endLuxon.toISODate() : '');
    searchParams.append('page', pageParam);
  }

  return searchParams;
}
