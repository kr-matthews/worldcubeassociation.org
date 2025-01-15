import React from 'react';
import { Header, Table } from 'semantic-ui-react';
import I18n from '../../../lib/i18n';
import { SeparateHeader } from '../TableHeaders';
import { SeparateRecordsRow } from '../TableRows';

export default function SeparateRecordsTable({ rows, competitionsById }) {
  const [, single, average] = rows;

  return (
    <>
      <Header>{I18n.t('results.selector_elements.type_selector.single')}</Header>
      <RankingTypeTable records={single} competitionsById={competitionsById} rankingType="single" />
      <Header>{I18n.t('results.selector_elements.type_selector.average')}</Header>
      <RankingTypeTable records={average} competitionsById={competitionsById} rankingType="average" />
    </>
  );
}

function RankingTypeTable({ records, rankingType, competitionsById }) {
  return (
    <Table basic="very" compact="very" striped unstackable singleLine>
      <SeparateHeader rankingType={rankingType} />
      <Table.Body>
        {records.map((row) => (
          <SeparateRecordsRow
            rankingType={rankingType}
            competition={competitionsById[row.competitionId]}
            result={row}
          />
        ))}
      </Table.Body>
    </Table>
  );
}
